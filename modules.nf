metadata = file(params.metadata)

process metadataTabulate {
    input: path qza
    output: path '*.qzv'

    shell:
    '''
    qiime metadata tabulate \
        --m-input-file !{qza} \
        --o-visualization !{qza.simpleName}.qzv
    '''
}

process featureTableSummarize {
    input: path tableQza
    output: path '*.qzv'

    shell:
    '''
    qiime feature-table summarize \
        --i-table !{tableQza} \
        --o-visualization !{tableQza.simpleName}.qzv \
        --m-sample-metadata-file !{metadata}
    '''
}