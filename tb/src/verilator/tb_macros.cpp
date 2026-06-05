#include "tb_macros.hh"

TbLogger logger;

TbLogger::TbLogger() {
  // By default, set the log level to medium
  this->log_lvl = LOG_MEDIUM;
  this->vcntx = NULL;
}

TbLogger::~TbLogger() {}

log_lvl_t TbLogger::log_lvl;

vluint64_t TbLogger::getSimTime() {
  if (this->vcntx != NULL)
    return this->vcntx->time();
  else
    return 0;
}

void TbLogger::setSimContext(VerilatedContext *cntx) {
  this->vcntx = cntx;
}

void TbLogger::setLogLvl(log_lvl_t lvl) {
  this->log_lvl = lvl;
}

void TbLogger::setLogLvl(char *lvl) {
  if (!strcmp(lvl, "LOG_NONE"))
    this->log_lvl = LOG_NONE;
  else if (!strcmp(lvl, "LOG_LOW"))
    this->log_lvl = LOG_LOW;
  else if (!strcmp(lvl, "LOG_HIGH"))
    this->log_lvl = LOG_HIGH;
  else if (!strcmp(lvl, "LOG_FULL"))
    this->log_lvl = LOG_FULL;
  else if (!strcmp(lvl, "LOG_DEBUG"))
    this->log_lvl = LOG_DEBUG;
  else
    this->log_lvl = LOG_MEDIUM;
}

void TbLogger::setLogLvl(int lvl) {
  switch (lvl) {
  case 0:
    this->log_lvl = LOG_NONE;
    break;
  case 1:
    this->log_lvl = LOG_LOW;
    break;
  case 2:
    this->log_lvl = LOG_MEDIUM;
    break;
  case 3:
    this->log_lvl = LOG_HIGH;
    break;
  case 4:
    this->log_lvl = LOG_FULL;
    break;
  case 5:
    this->log_lvl = LOG_DEBUG;
    break;
  default:
    this->log_lvl = LOG_MEDIUM;
    break;
  }
}

log_lvl_t TbLogger::getLogLvl() {
  return this->log_lvl;
}

static void print_location(const char *file, unsigned int line) {
  char n[256];
  strcpy(n, file);
  printf(" \033[2m(%s:%u)\033[0m", basename(n), line);
}

void TbLogger::log(log_lvl_t lvl, const char *file, const unsigned int line, const char *fmt, ...) {
  if (lvl <= this->log_lvl) {
    printf("\033[0m[ INF ] ");
    va_list arg_ptr;
    va_start(arg_ptr, fmt);
    vprintf(fmt, arg_ptr);
    va_end(arg_ptr);
    if (this->log_lvl >= LOG_DEBUG) print_location(file, line);
    printf("\n");
  }
}

void TbLogger::success(log_lvl_t lvl, const char *file, const unsigned int line, const char *fmt, ...) {
  if (lvl <= this->log_lvl) {
    printf("\033[1;32m[ OK! ]\033[0m ");
    va_list arg_ptr;
    va_start(arg_ptr, fmt);
    vprintf(fmt, arg_ptr);
    va_end(arg_ptr);
    if (this->log_lvl >= LOG_DEBUG) print_location(file, line);
    printf("\n");
  }
}

void TbLogger::config(const char *file, const unsigned int line, const char *fmt, ...) {
  printf("\033[1;36m[ CFG ]\033[0m ");
  va_list arg_ptr;
  va_start(arg_ptr, fmt);
  vprintf(fmt, arg_ptr);
  va_end(arg_ptr);
  if (this->log_lvl >= LOG_DEBUG) print_location(file, line);
  printf("\n");
}

void TbLogger::warning(const char *file, const unsigned int line, const char *fmt, ...) {
  fprintf(stderr, "\033[1;33m[WARN ]\033[0m ");
  va_list arg_ptr;
  va_start(arg_ptr, fmt);
  vfprintf(stderr, fmt, arg_ptr);
  va_end(arg_ptr);
  if (this->log_lvl >= LOG_DEBUG) print_location(file, line);
  fprintf(stderr, "\n");
}

void TbLogger::error(const char *file, const unsigned int line, const char *fmt, ...) {
  fprintf(stderr, "\033[1;31m[ ERR ]\033[0m ");
  va_list arg_ptr;
  va_start(arg_ptr, fmt);
  vfprintf(stderr, fmt, arg_ptr);
  va_end(arg_ptr);
  if (this->log_lvl >= LOG_DEBUG) print_location(file, line);
  fprintf(stderr, "\n");
}
