# Generate tb_cheshire_util.svh with the correct number of sets for the LLC
# starting from a mako template.
import pathlib
import re
import argparse
from mako.template import Template

# Compile a regex to trim trailing whitespaces on lines
re_trailws = re.compile(r'[ \t\r]+$', re.MULTILINE)

def write_template(tpl_path, outdir, **kwargs):
    if tpl_path is not None:
        tpl_path = pathlib.Path(tpl_path).absolute()
        if tpl_path.exists():
            tpl = Template(filename=str(tpl_path))
            with open(outdir / tpl_path.with_suffix("").name, 'w', encoding='utf-8') as f:
                code = tpl.render_unicode(**kwargs)
                code = re_trailws.sub('', code)
                f.write(code)
        else:
            raise FileNotFoundError(f'Template file {tpl_path} not found')

def main():
  parser = argparse.ArgumentParser(description="Generate tb_cheshire_util.svh")
  parser.add_argument("--sets-assoc",
                        type=int,
                        default=8,
                        help="Set associativity for the AXI LLC (1, 2, 4, 8...)")
  parser.add_argument('--tpl-sv',
                          '-s',
                          type=str,
                          metavar='SV',
                          help='SystemVerilog template filename')
  parser.add_argument('--outdir',
                      '-o',
                      metavar='DIR',
                      type=pathlib.Path,
                      required=True,
                      help='Output directory')
  args = parser.parse_args()


  kwargs = {
      'LlcSetAssoc': args.sets_assoc
  }

  # Generate SystemVerilog package
  if args.tpl_sv is not None:
    write_template(args.tpl_sv, args.outdir, **kwargs)


if __name__ == '__main__':
    main()