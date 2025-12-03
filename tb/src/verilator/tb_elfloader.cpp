// Copyright 2022 ETH Zurich and University of Bologna.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0
//
// Modified version of the RISC-V Frontend Server 
// (https://github.com/riscvarchive/riscv-fesvr, e41cfc3001293b5625c25412bd9b26e6e4ab8f7e)
//
// Nicole Narr <narrn@student.ethz.ch>
// Christopher Reinwardt <creinwar@student.ethz.ch>

#include "tb_elfloader.hh"
#include <iostream>
#include <string>

// Declare here as used by static methods
// memory based address and content
std::map<uint64_t, std::vector<uint8_t>> mems;
// address and size
std::vector<std::pair<uint64_t, uint64_t>> sections;

// Entrypoint
size_t section_index = 0;
long long entry = 0;


void TbElfLoader::write (uint64_t address, uint64_t len, uint8_t *buf)
{
  std::vector<uint8_t> mem;
  for (int i = 0; i < len; i++) {
    mem.push_back(buf[i]);
  }
  mems.insert(std::make_pair(address, mem));
}

// Return the entry point reported by the ELF file
// Must be called after reading the elf file obviously
char TbElfLoader::get_entry(long long *entry_ret)
{
  *entry_ret = entry;
  return 0;
}

// Iterator over the section addresses and lengths
// Returns:
// 0 if there are no more sections
// 1 if there are more sections to load
//char TbElfLoader::get_section(long long *address_ret, long long *len_ret)
//{
//  if (section_index < sections.size()) {
//    *address_ret = sections[section_index].first;
//    *len_ret = sections[section_index].second;
//    section_index++;
//    return 1;
//  } else {
//    return 0;
//  }
//}

char TbElfLoader::get_section(long long *address_ret, long long *len_ret)
{
  if (section_index < sections.size()) {
    *address_ret = sections[section_index].first;

    // Updated to get actual size from mems
    auto it = mems.find(*address_ret);
    if (it != mems.end()) {
      *len_ret = it->second.size();
    } else {
      printf("[ELF] WARNING: Section at %p not found in memory map!\n", *address_ret);
      *len_ret = 0;
    }
    section_index++;
    return 1;
  } else {
    return 0;
  }
}



char TbElfLoader::read_section_chunk(long long base, long long offset, char* buffer, long long len)
{
  // check that the base address points to a section
  if (!mems.count(base)) {
    printf("[ELF] ERROR: No section found for base address %p\n", base);
    return -1;
  }

  // get memory vector for this section
  auto mem = mems.find(base)->second;

  // check for out-of-bounds access
  if (offset < 0 || len < 0 || ((offset + len) > mem.size())) {
    printf("[ELF] ERROR: Offset %0p, length %d out of bounds for section at %p with length %d\n", offset, len, base, mem.size());
    return -1;
  }
  // copy data to SV array
  std::copy(mem.begin() + offset, mem.begin() + offset + len, buffer);

  return 0;
}

template <class E, class P, class Sh, class Sy>
void TbElfLoader::load_elf(char *buf, size_t size)
{
  E  *eh = (E *)   buf;
  P  *ph = (P *)  (buf + eh->e_phoff);
  Sh *sh = (Sh *) (buf + eh->e_shoff);

  char *shstrtab = NULL;

  if(size < eh->e_phoff + (eh->e_phnum * sizeof(P))){
    printf("[ELF] ERROR: Filesize is smaller than advertised program headers (0x%lx vs 0x%lx)\n", size, eh->e_phoff + (eh->e_phnum * sizeof(P)));
    return;
  }

  entry = eh->e_entry;
  printf("[ELF] INFO: Entrypoint at %p\n", entry);

  // Iterate over all program header entries
  for (unsigned int i = 0; i < eh->e_phnum; i++) {
    // Check whether the current program header entry contains a loadable section of nonzero size
    if(ph[i].p_type == PT_LOAD && ph[i].p_memsz) {
      // Is this section something else than zeros?
      if (ph[i].p_filesz) {
        assert(size >= ph[i].p_offset + ph[i].p_filesz);
        sections.push_back(std::make_pair(ph[i].p_paddr, ph[i].p_memsz));
        write(ph[i].p_paddr, ph[i].p_filesz, (uint8_t*)buf + ph[i].p_offset);
      }

      if(ph[i].p_memsz > ph[i].p_filesz){
        printf("[ELF] WARNING: The section starting @ %p contains 0x%lx zero bytes which will NOT be preloaded!\n",
               ph[i].p_paddr, (ph[i].p_memsz - ph[i].p_filesz));
      }
    }
  }

  if(size < eh->e_shoff + (eh->e_shnum * sizeof(Sh))){
    printf("[ELF] ERROR: Filesize is smaller than advertised section headers (0x%lx vs 0x%lx)\n",
           size, eh->e_shoff + (eh->e_shnum * sizeof(Sh)));
    return;
  }

  if(eh->e_shstrndx >= eh->e_shnum){
    printf("[ELF] ERROR: Malformed ELF file. The index of the section header strings is out of bounds (0x%lx vs max 0x%lx)",
           eh->e_shstrndx, eh->e_shnum);
    return;
  }
  
  if(size < sh[eh->e_shstrndx].sh_offset + sh[eh->e_shstrndx].sh_size){
    printf("[ELF] ERROR: Filesize is smaller than advertised size of section name table (0x%lx vs 0x%lx)\n",
           size, sh[eh->e_shstrndx].sh_offset + sh[eh->e_shstrndx].sh_size);
    return;
  }

  // Get a direct pointer to the section name section
  shstrtab = buf + sh[eh->e_shstrndx].sh_offset;
  unsigned int strtabidx = 0, symtabidx = 0;

  // Iterate over all section headers to find .strtab and .symtab
  for (unsigned int i = 0; i < eh->e_shnum; i++) {
    // Get an upper limit on how long the name can be (length of the section name section minus the offset of the name)
    unsigned int max_len = sh[eh->e_shstrndx].sh_size - sh[i].sh_name;

    // Is this the string table?
    if(strcmp(shstrtab + sh[i].sh_name, ".strtab") == 0){
      printf("[ELF] INFO: Found string table at offset 0x%lx\n", sh[i].sh_offset);
      strtabidx = i;
      continue;
    }

    // Is this the symbol table?
    if(strcmp(shstrtab + sh[i].sh_name, ".symtab") == 0){
      printf("[ELF] INFO: Found symbol table at offset 0x%lx\n", sh[i].sh_offset);
      symtabidx = i;
      continue;
    }
  }
}

char TbElfLoader::read_elf(const char *filename)
{
  char *buf = NULL;
  Elf64_Ehdr* eh64 = NULL;
  int fd = open(filename, O_RDONLY);
  char retval = 0;
  struct stat s;
  size_t size = 0;

  if(fd == -1){
    printf("[ELF] ERROR: Unable to open file %s\n", filename);
    retval = -1;
    goto exit;
  }

  if(fstat(fd, &s) < 0) {
    printf("[ELF] ERROR: Unable to read stats for file %s\n", filename);
    retval = -1;
    goto exit_fd;
  }

  size = s.st_size;

  if(size < sizeof(Elf64_Ehdr)){
    printf("[ELF] ERROR: File %s is too small to contain a valid ELF header (0x%lx vs 0x%lx)\n", filename, size, sizeof(Elf64_Ehdr));
    retval = -1;
    goto exit_fd;
  }

  buf = (char *) mmap(NULL, size, PROT_READ, MAP_PRIVATE, fd, 0);
  if(buf == MAP_FAILED){
    printf("[ELF] ERROR: Unable to memory map file %s\n", filename);
    retval = -1;
    goto exit_fd;
  }

  printf("[ELF] INFO: File %s was memory mapped to %p\n", filename, buf);

  eh64 = (Elf64_Ehdr *) buf;

  if(!(IS_ELF32(*eh64) || IS_ELF64(*eh64))){
    printf("[ELF] ERROR: File %s does not contain a valid ELF signature\n", filename);
    retval = -1;
    goto exit_mmap;
  }

  if (IS_ELF32(*eh64)){
    load_elf<Elf32_Ehdr, Elf32_Phdr, Elf32_Shdr, Elf32_Sym>(buf, size);
  } else {
    load_elf<Elf64_Ehdr, Elf64_Phdr, Elf64_Shdr, Elf64_Sym>(buf, size);
  }

exit_mmap:
  munmap(buf, size);

exit_fd:
  close(fd);

exit:
  return retval;
}
