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
  'Unit Test': [
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
  firstStageInitTask: {
    sh """#!/bin/bash -l
      ls -l pkg/main/default/translations/en_US.translation-meta.xml
      cat pkg/main/default/translations/en_US.translation-meta.xml
      """.stripIndent()
  }
)
