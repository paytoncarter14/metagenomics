// TODO: pull p-values from alpha and beta tests
// TODO: Mantel test?

metadata = file(params.metadata)
classifier = file(params.classifier)

include {metadataTabulate} from './modules'
include {metadataTabulate as metadataTabulate2} from './modules'
include {featureTableSummarize} from './modules'
include {featureTableSummarize as featureTableSummarize2} from './modules'
include {featureTableSummarize as featureTableSummarize3} from './modules'

process demuxFilterSamples {
    input: path qza
    output: path 'demux-filter-samples.qza'

    shell:
    '''
    qiime demux filter-samples \
        --i-demux !{qza} \
        --m-metadata-file !{metadata} \
        --p-where "!{params.demuxFilterSamplesString}" \
        --o-filtered-demux demux-filter-samples.qza
    '''
}

process demuxSummarize {
    input: path qza
    output: path 'demux-filter-samples.qzv'

    shell:
    '''
    qiime demux summarize \
        --i-data !{qza} \
        --o-visualization demux-filter-samples.qzv
    '''
}

process dada2DenoisePaired {
    input: path qza
    output:
        path 'rep-seqs.qza', emit: repSeqs
        path 'table.qza', emit: table
        path 'dada2-stats.qza', emit: dada2Stats

    shell:
    '''
    qiime dada2 denoise-paired \
        --i-demultiplexed-seqs !{qza} \
        --p-trunc-len-f !{params.dada2DenoisePairedTruncLenF} \
        --p-trunc-len-r !{params.dada2DenoisePairedTruncLenR} \
        --p-n-threads 0 \
        --o-representative-sequences rep-seqs.qza \
        --o-table table.qza \
        --o-denoising-stats dada2-stats.qza
    '''
}

process featureTableTabulateSeqs {
    input: path repSeqsQza
    output: path 'rep-seqs.qzv'

    shell:
    '''
    qiime feature-table tabulate-seqs \
        --i-data !{repSeqsQza} \
        --o-visualization rep-seqs.qzv
    '''
}

process featureClassifierClassifySklearn {
    input: path repSeqsQza
    output: path 'taxonomy.qza'

    shell:
    '''
    qiime feature-classifier classify-sklearn \
        --i-classifier !{classifier} \
        --i-reads !{repSeqsQza} \
        --p-n-jobs 0 \
        --o-classification taxonomy.qza
    '''
}

process taxaFilterTable {
    input:
        path tableQza
        path taxonomyQza
    output: path 'table-filtered.qza'

    shell:
    '''
    qiime taxa filter-table \
        --i-table !{tableQza} \
        --i-taxonomy !{taxonomyQza} \
        --p-exclude !{params.taxaFilterTableExcludeString} \
        --o-filtered-table table-filtered.qza
    '''
}

process phylogenyAlignToTreeMafftFasttree {
    input: path repSeqsQza
    output:
        path 'rep-seqs-aligned.qza', emit: repSeqsAligned
        path 'rep-seqs-aligned-masked.qza', emit: repSeqsAlignedMasked
        path 'tree-unrooted.qza', emit: treeUnrooted
        path 'tree-rooted.qza', emit: treeRooted

    shell:
    '''
    qiime phylogeny align-to-tree-mafft-fasttree \
        --i-sequences rep-seqs.qza \
        --p-n-threads auto \
        --o-alignment rep-seqs-aligned.qza \
        --o-masked-alignment rep-seqs-aligned-masked.qza \
        --o-tree tree-unrooted.qza \
        --o-rooted-tree tree-rooted.qza
    '''
}

process diversityCoreMetricsPhylogenetic {
    input:
        path treeRootedQza
        path tableQza
    output:
        path 'core-metrics/bray_curtis_distance_matrix.qza', emit: brayCurtisDistanceMatrix
        path 'core-metrics/bray_curtis_emperor.qzv', emit: brayCurtisEmperor
        path 'core-metrics/bray_curtis_pcoa_results.qza', emit: brayCurtisPcoaResults
        path 'core-metrics/evenness_vector.qza', emit: evennessVector
        path 'core-metrics/faith_pd_vector.qza', emit: faithPdVector
        path 'core-metrics/jaccard_distance_matrix.qza', emit: jaccardDistanceMatrix
        path 'core-metrics/jaccard_emperor.qzv', emit: jaccardEmperor
        path 'core-metrics/jaccard_pcoa_results.qza', emit: jaccardPcoaResults
        path 'core-metrics/observed_features_vector.qza', emit: observedFeaturesVector
        path 'core-metrics/rarefied_table.qza', emit: rarefiedTable
        path 'core-metrics/shannon_vector.qza', emit: shannonVector
        path 'core-metrics/unweighted_unifrac_distance_matrix.qza', emit: unweightedUnifracDistanceMatrix
        path 'core-metrics/unweighted_unifrac_emperor.qzv', emit: unweightedUnifracEmperor
        path 'core-metrics/unweighted_unifrac_pcoa_results.qza', emit: unweightedUnifracPcoaResults
        path 'core-metrics/weighted_unifrac_distance_matrix.qza', emit: weightedUnifracDistanceMatrix
        path 'core-metrics/weighted_unifrac_emperor.qzv', emit: weightedUnifracEmperor
        path 'core-metrics/weighted_unifrac_pcoa_results.qza', emit: weightedUnifracPcoaResults

    shell:
    '''
    qiime diversity core-metrics-phylogenetic \
        --i-phylogeny !{treeRootedQza} \
        --i-table !{tableQza} \
        --p-sampling-depth !{params.samplingDepth} \
        --p-n-jobs-or-threads auto \
        --m-metadata-file !{metadata} \
        --output-dir core-metrics
    '''
}

process diversityAlphaRarefaction {
    input:
        path tableQza
        path treeRootedQza
    output: path 'alpha-rarefaction.qzv'

    shell:
    '''
    qiime diversity alpha-rarefaction \
        --i-table !{tableQza} \
        --i-phylogeny !{treeRootedQza} \
        --p-max-depth !{params.samplingDepth} \
        --m-metadata-file !{metadata} \
        --o-visualization alpha-rarefaction.qzv
    '''
}

process taxaBarplot {
    input:
        path tableQza
        path taxonomyQza
    output: path 'taxonomy-bar-plot.qzv'

    shell:
    '''
    qiime taxa barplot \
        --i-table !{tableQza} \
        --i-taxonomy !{taxonomyQza} \
        --m-metadata-file !{metadata} \
        --o-visualization taxonomy-bar-plot.qzv
    '''
}

process diversityAlphaGroupSignificance {
    input: path vectorQza
    output: path 'alpha-group-significance-*.qzv'

    shell:
    '''
    qiime diversity alpha-group-significance \
        --i-alpha-diversity !{vectorQza} \
        --m-metadata-file !{metadata} \
        --o-visualization alpha-group-significance-!{vectorQza.simpleName}.qzv \
    '''
}

process diversityBetaGroupSignificance {
    input:
        path distanceMatrixQza
        each column
    output: path 'beta-group-significance-*.qzv'

    shell:
    '''
    qiime diversity beta-group-significance \
        --i-distance-matrix !{distanceMatrixQza} \
        --m-metadata-file !{metadata} \
        --m-metadata-column !{column} \
        --o-visualization beta-group-significance-!{distanceMatrixQza.simpleName}-!{column}.qzv \
        --p-pairwise \
    '''
}

process compositionAncombc {
    input:
        path tableQza
        each column
    output: path 'ancombc-*.qza'

    shell:
    '''
    qiime composition ancombc \
        --i-table !{tableQza} \
        --m-metadata-file !{metadata} \
        --p-formula '!{column}' \
        --o-differentials ancombc-!{column}.qza
    '''
}

process compositionDaBarplot {
    input: path ancombcQza
    output: path '*.qzv'

    shell:
    '''
    qiime composition da-barplot \
        --i-data !{ancombcQza} \
        --p-significance-threshold !{params.ancombcSignificanceThreshold} \
        --o-visualization !{ancombcQza.simpleName}.qzv
    '''
}

workflow {

    // initial filtering of demux by metadata
    demuxFilterSamples(Channel.fromPath(params.demux))
    demuxSummarize(demuxFilterSamples.out)

    // denoise and QC with DADA2
    dada2DenoisePaired(demuxFilterSamples.out)
    metadataTabulate(dada2DenoisePaired.out.dada2Stats)
    featureTableSummarize(dada2DenoisePaired.out.table)
    featureTableTabulateSeqs(dada2DenoisePaired.out.repSeqs)

    // taxonomic classification
    featureClassifierClassifySklearn(dada2DenoisePaired.out.repSeqs)
    metadataTabulate2(featureClassifierClassifySklearn.out)

    // filter table by taxonomy
    taxaFilterTable(dada2DenoisePaired.out.table, featureClassifierClassifySklearn.out)
    featureTableSummarize2(taxaFilterTable.out)

    // core phylo metrics
    phylogenyAlignToTreeMafftFasttree(dada2DenoisePaired.out.repSeqs)
    diversityCoreMetricsPhylogenetic(phylogenyAlignToTreeMafftFasttree.out.treeRooted, taxaFilterTable.out)

    // make alpha rarefaction plot, stats for rarefied table, and taxa barplot
    featureTableSummarize3(diversityCoreMetricsPhylogenetic.out.rarefiedTable)
    diversityAlphaRarefaction(diversityCoreMetricsPhylogenetic.out.rarefiedTable, phylogenyAlignToTreeMafftFasttree.out.treeRooted)
    taxaBarplot(diversityCoreMetricsPhylogenetic.out.rarefiedTable, featureClassifierClassifySklearn.out)

    // taxa barplot grouped by metadata

    // alpha group significance
    diversityAlphaGroupSignificance(diversityCoreMetricsPhylogenetic.out.evennessVector.mix(diversityCoreMetricsPhylogenetic.out.faithPdVector,
        diversityCoreMetricsPhylogenetic.out.observedFeaturesVector,
        diversityCoreMetricsPhylogenetic.out.shannonVector))

    // beta group significance
    diversityBetaGroupSignificance(diversityCoreMetricsPhylogenetic.out.brayCurtisDistanceMatrix.mix(
        diversityCoreMetricsPhylogenetic.out.unweightedUnifracDistanceMatrix,
        diversityCoreMetricsPhylogenetic.out.weightedUnifracDistanceMatrix,
        diversityCoreMetricsPhylogenetic.out.unweightedUnifracDistanceMatrix,
        diversityCoreMetricsPhylogenetic.out.jaccardDistanceMatrix),
    params.columns)

    // ancombc differential abundance
    compositionAncombc(diversityCoreMetricsPhylogenetic.out.rarefiedTable, params.columns)
    compositionDaBarplot(compositionAncombc.out)
}