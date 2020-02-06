# Snakemake_nanometh

## Dependencies

- Python3
  - <a href="https://bitbucket.org/snakemake/snakemake" target=_blank>Snakemake</a>
- <a href="https://github.com/lh3/minimap2" target=_blank>minimap2</a>
- <a href="https://github.com/jts/nanopolish" target=_blank>nanopolish</a>
- <a href="http://www.htslib.org/"> SAMtools </a>

## Usage

**This pipeline is thought to run in CNAG cluster.**

It uses `module system` to load every tool that is need in each step. Feel free to change Snakefile to fit it each step to you needs.

If you install every tool in your path, you can comment each `^module` line.

### 1. Prepare Data

#### Required files

- Fast5 files unzipped
- Reference indexed by `samtools index` or bgzipped
- Fastq.gz files
  
#### CMD

```bash
prepareData.py \
-f /path/to/fastq/*gz \
-5 /path/to/fast5/folder \
-r /path/to/reference.fa \
-s /path/to/sequence_summary.txt \
-o /path/to/output/folder > file.config.json

```

>**NOTE**
>*********************
>
> - If your fast5 files are multisequence, avoid sequence_summary file parameter.
>
> - `splitted` is forced to `false`.

### 2. Run pipeline

It depends on your system. As an example, in our cluster we run in this way:

```bash
snakemake \
-s snakemake_nanometh/Snakefile \
--jobs 999 \
--nt \
--configfile file.config.json \
--cluster 'Snakemake-CNAG/sbatch-cnag.py {dependencies}' \
--is
```

### 3. Extra configuration

Times and threads are set up for our cluster's configuration.

Feel free to change the code or use a configuration file to change resources per each rule.

If you don't want to change the code, you can use de run.default.cnf file.

## Other

CNAG's Snakemake cluster submitter wrapper script is at https://github.com/jesgomez/Snakemake-CNAG