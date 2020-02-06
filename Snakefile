
__author__ = 'Marc Dabad'
__email__ = "marc.dabad@cnag.crg.cat"

import os

### Prepare pipeline and enviroment
shell.prefix("source ~/.bashrc")
path_snakemake = os.path.dirname(workflow.snakefile)



out = os.path.abspath(config.get('output', os.getcwd()))
workdir: out
mappings = out+"/mappings/"
calls = out+"/calls/"
results = out+"/results/"


os.makedirs(mappings, exist_ok=True)
os.makedirs(calls, exist_ok=True)
os.makedirs(results, exist_ok=True)
config['splitted'] = False

BASENAME = dict()
for i in config['fastq']:
    BASENAME[os.path.basename(i).split(".fastq")[0]] = i

analysis_set = ['cpg', 'gpc', 'dam', 'dcm']


### Pipeline's rules
if config['splitted']:
    rule all:
        input:
            expand(results+'whole.{analysis}', analysis=analysis_set)
            

else:
    rule all:
        input:
            expand(results+'{sample}.{analysis}', sample=BASENAME.keys(), analysis=analysis_set)

### Mapping step
rule mappings:
    input:
        fastq = lambda wildcards: BASENAME[wildcards.sample]
    params:
        ref = config['reference'],
        time= "2:00:00",
        name= "mapping.{sample}"
    threads: 16
    output:
        bam = mappings+'{sample}.bam',
        bai = mappings+'{sample}.bam.bai'


    shell:
        '''
module purge
module load gcc/6.3.0 samtools/1.6 MINIMAP2 NANOPOLISH/0.11.0

minimap2 -t {threads} -L --MD -a -x map-ont {params.ref} {input.fastq}  | \
samtools view -@ {threads} -q 10 -b - | \
samtools sort -@ {threads} -T $TMPDIR -o {output.bam}
samtools index {output.bam}
        '''

### Index fastq

if config['summary']:
    rule nanopolish_index_summary:
        input:
            fastq = lambda wildcards: BASENAME[wildcards.sample]
        
        params:
            fast5 = config['path_fast5'],
            summary_seq= config['summary'],
            time = "10:00:00",
            name = "index_fastq.summary.{sample}"

        threads: 8
        output:
            touch(out+'/{sample}.index.done')

        shell:
            '''
    module purge
    module load gcc/6.3.0 samtools/1.6 minimap2 nanopolish
    nanopolish index -d {params.fast5} -s {params.summary_seq} {input.fastq}
            '''
else:
    rule nanopolish_index:
        input:
            fastq = lambda wildcards: BASENAME[wildcards.sample]

        params:
            fast5 = config['path_fast5'],
            time = "3-00:00:00",
            qos = "xlong",
            name= "index_fastq.{sample}"
        threads: 8
        output:
            touch(out+'/{sample}.index.done')
        shell:
            '''
    module purge
    module load gcc/6.3.0 samtools/1.6 minimap2 nanopolish
    nanopolish index -d {params.fast5} {input.fastq}

    #touch {output}
            '''


#### CALL methyl
if config['splitted']:
    rule join_methCalls:
        input:
            methCalls = expand(calls+"{sample}.{{analysis}}", 
                                sample=BASENAME.keys())
        
        threads: 8
        params:
            name= 'join_methCalls.{analysis}.whole'
        output:
            results+'whole.{analysis}'

        shell:
            '''
    {path_snakemake}/bin/calc_methyl_freq -t {threads} {input.methCalls} > {output}
            '''

else:
    rule methCalls_step:
        input:
            methCalls = calls+"{sample}.{analysis}"
        
        threads: 8
        params:
            name= 'methCalls.{sample}.{analysis}'
        output:
            results+'{sample}.{analysis}'

        shell:
            '''
    {path_snakemake}/bin/calc_methyl_freq -t {threads} {input.methCalls} > {output}
            '''

rule nanopolish_call:
        input:
            bam = mappings+'{sample}.bam',
            fastq = lambda wildcards: BASENAME[wildcards.sample],
            index = rules.nanopolish_index_summary.output if config['summary'] else rules.nanopolish_index.output
        
        params:
            ref = config['reference'],
	        analysis = '{analysis}',
            time = "48:00:00",
            name= "nanopolish_call.{sample}.{analysis}"

        threads: 8

        output:
            calls+'{sample}.{analysis}'

        shell:
            '''
    module purge
    module load gcc/6.3.0 samtools/1.6 minimap2 nanopolish
    nanopolish call-methylation -t {threads} \
    -r {input.fastq} \
    -b {input.bam} \
    -g {params.ref} -q {params.analysis}  > {output}

            '''
