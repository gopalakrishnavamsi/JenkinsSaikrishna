library 'docusign-common'

def defaultSalesforceArgs = [
  jwtKeyFileCredsId: 'salesforce-jwt-key-file',
  consumerKeyCredsId: 'salesforce-consumer-key',
  hubUsername: 'dfsdev@devhub.com',
  orgDefFilePath: 'etc/test.json',
  scratchOrgName: 'scratchorg',
  adminUsername: 'DocuSign_Administrator'
]

def defaultPostBuildTests = [
  'Test': [
    outputDir: 'tests',
    outputPath: 'tests/*-junit.xml',
    reporter: 'xunit',
    reportFormat: 'junit'
  ]
]

salesforcePipeline(
  appName: 'salesforce-core',
  postBuildTests: defaultPostBuildTests,
  salesforceArgs: defaultSalesforceArgs,
  doSonarQube: true,
  skipSherlockCi: true
)
