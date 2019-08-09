/**
* Initializes new custom settings in 2.0.
*/
public class PostInstall2 implements PostInstallScript {
    
    @TestVisible
    private static PostInstallResults initializeAccountSettings() {
        Boolean didInit = false;
        PostInstallResults result = new PostInstallResults();
        AccountSettings__c settings = AccountSettings__c.getOrgDefaults();
        
        if (settings.IsESignatureEnabled__c != true) {
            settings.IsESignatureEnabled__c = true;
            didInit = true;
        }
        
        if (String.isBlank(settings.EncryptionKey__c)) {
            settings.EncryptionKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
            didInit = true;
        }
        
        if (didInit) {
            update settings;
            result.endStepSuccess(Label.InitializeAccountSettings);
        } else {
            result.skipStep(Label.InitializeAccountSettings, Label.AlreadyComplete);
        }
        return result;
    }
    
    @TestVisible
    private static PostInstallResults createDefaultCLMObjMappings(){
        PostInstallResults result = new PostInstallResults();        
        try{
            if(EOS_Type__c.getOrgDefaults().Id == null){
                insertDefaultCLMObjMappings();                               
            } else{
                result.skipStep(Label.CreateDefaultCLMObjMappings, Label.AlreadyComplete);
            }
        }catch(Exception ex){
            result.endStepFailure(Label.CreateDefaultCLMObjMappings, ex);
        }
        return result;
    }
    
    private static void insertDefaultCLMObjMappings(){
        EOS_Type__c eos_Account = new EOS_Type__c();        
        eos_Account.FolderName__c = Label.DefaultAccountFolderName;
        eos_Account.Path__c = Label.DefaultAccountObjectMappingPath;
        eos_Account.FolderNameFormat__c	= Label.DefaultFolderNameFormat;
        eos_Account.Variables__c = Label.DefaultAccountVariables;
        eos_Account.PathFormat__c = Label.DefaultAccountPathFormat;			
        eos_Account.Name = Label.Account;
        insert eos_Account;
        
        EOS_Type__c eos_Opportunity = new EOS_Type__c();
        eos_Opportunity.FolderName__c = Label.DefaultOpportunityFolderName;
        eos_Opportunity.Path__c = Label.DefaultOpportunityObjectMappingPath;
        eos_Opportunity.FolderNameFormat__c	= Label.DefaultFolderNameFormat;
        eos_Opportunity.Variables__c = Label.DefaultOpportunityVariables;
        eos_Opportunity.PathFormat__c = Label.DefaultOpportunityPathFormat;			
        eos_Opportunity.Name = Label.Opportunity;						        
        insert eos_Opportunity;           
    }
    
    public Boolean shouldExecute(Id organizationId, Id installerId, Version previousVersion, Boolean isPush,
                                 Boolean isUpgrade) {
                                     
                                     return previousVersion != null
                                         && previousVersion.major() < 2;
                                 }
    
    public PostInstallResults execute(Id organizationId, Id installerId, Version previousVersion, Boolean isPush,
                                      Boolean isUpgrade) {
                                          
                                          return new PostInstallResults().addResults(initializeAccountSettings()).addResults(createDefaultCLMObjMappings());
                                      }
}