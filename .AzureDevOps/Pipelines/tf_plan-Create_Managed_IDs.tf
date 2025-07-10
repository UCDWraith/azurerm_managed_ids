trigger: none

pool:
  vmImage: 'ubuntu-latest'

parameters:
  - name: SubscriptionJSON
    displayName: 'Subscription JSON File'
    type: string
    default: 'Subscription-identity.json'
    values:
      - 'Subscription-sample.json'
      - 'Subscription-sample_dev.json'
      
variables:
  - group: 'tf_managed_identities-PRD'

jobs:
- job: SetupVars
  displayName: 'Setup Variables'
  steps:
    - bash: |
        echo "Original: ${{ parameters.SubscriptionJSON }}"
        # Strip 'Subscription-' prefix and '.json' suffix
        SUB_NAME=$(echo "${{ parameters.SubscriptionJSON }}" | sed -e 's/^Subscription-//' -e 's/\.json$//')
        echo "Extracted: $SUB_NAME"
        # Set pipeline variable
        echo "##vso[task.setvariable variable=subscriptionName;isOutput=true]$SUB_NAME"
        PLAN_NAME="Create-Managed_IDs-${SUB_NAME}.tfplan"
        echo "Extracted: $PLAN_NAME"
        # Set pipeline variable
        echo "##vso[task.setvariable variable=customPlanName;isOutput=true]$PLAN_NAME"
      displayName: 'Extract subscription name from JSON file'
      name: ExtractVars

    - bash: |
        echo '{ "subscription": "$(ExtractVars.subscriptionName)", "customBackendKey": "$(backendAzureRmKeyBase)$(ExtractVars.subscriptionName).tfstate", "customPlanName": "$(ExtractVars.customPlanName)"}' > output.json
      displayName: 'Write values to JSON'

    - publish: output.json
      artifact: pipelineParams
      displayName: 'Publish parameters as artifact'

- job: tfplan
  dependsOn: SetupVars
  condition: succeeded()
  displayName: 'Terraform plan + generate artifact'
  variables:
    subscriptionName: $[ dependencies.SetupVars.outputs['ExtractVars.subscriptionName'] ]
    customPlanName: $[ dependencies.SetupVars.outputs['ExtractVars.customPlanName'] ]
  steps:
    - task: TerraformInstaller@1
      displayName: 'Terraform Install'
      inputs:
        terraformVersion: 'latest'

    - task: TerraformTask@5
      displayName: 'Terraform init'
      inputs:
        provider: 'azurerm'
        command: 'init'
        backendServiceArm: '$(svc_connection)'
        backendAzureRmResourceGroupName: '$(backendAzureRmResourceGroupName)'
        backendAzureRmStorageAccountName: '$(backendAzureRmStorageAccountName)'
        backendAzureRmContainerName: '$(backendAzureRmContainerName)'
        backendAzureRmKey: '$(backendAzureRmKeyBase)$(subscriptionName).tfstate'
        workingDirectory: '$(tf_working_dir)'

    - task: TerraformTask@5
      displayName: 'Terraform validate'
      inputs:
        provider: 'azurerm'
        command: 'validate'
        workingDirectory: '$(tf_working_dir)'

    - task: TerraformTask@5
      displayName: 'Terraform plan'
      inputs:
        provider: 'azurerm'
        command: 'plan'
        workingDirectory: '$(tf_working_dir)'
        commandOptions: '-var-file="./library/${{ parameters.SubscriptionJSON }}" -out=$(Pipeline.Workspace)/a/$(customPlanName) -no-color'
        environmentServiceNameAzureRM: $(svc_connection)

    - task: TerraformTask@5
      displayName: 'Terraform show'
      inputs:
        provider: 'azurerm'
        command: 'show'
        workingDirectory: '$(tf_working_dir)'
        commandOptions: '$(Pipeline.Workspace)/a/$(customPlanName) -no-color'
        outputTo: 'file'
        outputFormat: 'default'
        fileName: '$(Pipeline.Workspace)/s/TerraformPlan.raw'
        environmentServiceNameAzureRM: $(svc_connection)
    
    - task: Bash@3
      displayName: 'Create plan summary file'
      inputs:
        targetType: 'inline'
        workingDirectory: '$(System.DefaultWorkingDirectory)'
        script: |
          cat TerraformPlan.raw
          # Convert to Markdown and wrap with code block
          echo '```terraform' > TerraformPlan.md
          cat TerraformPlan.raw >> TerraformPlan.md
          echo '```' >> TerraformPlan.md
          echo "##vso[task.uploadsummary]$(System.DefaultWorkingDirectory)/TerraformPlan.md"
          
    - task: PublishPipelineArtifact@1
      displayName: 'Publish Terraform Plan Artifact'
      inputs:
        targetPath: '$(Pipeline.Workspace)/a/$(customPlanName)'
        artifact: 'terraformPlan'
