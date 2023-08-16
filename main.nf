process generate_random_table {
    publishDir "results", mode: 'copy'
    container 'quay.io/lifebitaiorg/ubuntu:18.10'

    output:
    file("random_table.csv") into ch_random_table

    script:
    """
    touch random_table.csv
    for (( i=1; i<=${params.number_of_rows}; i++ )); do
        row=(\$(shuf -i 1-100 -n 3))
        echo "\${row[0]},\${row[1]},\${row[2]}" >> random_table.csv
    done
    """
}

process trigger_next_pipeline {
    container 'quay.io/lifebitaiorg/cloudos-cli:v2.6.0'

    input:
    file(random_table) from ch_random_table
    
    script:
    // get the table name from NF channel and combine with results location to get s3 path
    table_full_path="${{JOB_RESULTS_LOCATION}}/$random_table"
    """
    cloudos job run \
        --job-name "job-triggred-from-workflow-1-with-cloudos-cli" \
        --cloudos-url ${params.cloudos_url} \
        --workspace-id ${params.cloudos_workspace} \
        --project-name ${params.cloudos_project_name} \
        --workflow-name ${params.cloudos_workflow_name} \
        --apikey ${params.cloudos_apikey} \
        --batch \
        --parameter input=${table_full_path}
    """
}