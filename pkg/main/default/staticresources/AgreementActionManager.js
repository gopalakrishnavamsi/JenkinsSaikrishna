var generateComponent = function(anchor, component, componentName, attributes) {
    return new Promise((resolve, reject) => {
        try {
            $A.createComponent(
                componentName,
                attributes,
                (result, err, msg) => {
                    if (err && msg) reject(msg);
                    var container = component.find(anchor);
                    if (container && container.isValid()) {
                        var body = container.get('v.body');
                        body.push(result);
                        container.set('v.body', body);
                        resolve(result);
                    } else {
                      console.log('cant find container');
                    }
                }
            );
        } catch (err) {
          throw err;
        }
    });
};


var AgreementComponents = Object.freeze({
    Upload: 'AgreementsUploadNewVersion',
    Delete: 'AgreementsDelete',
    InternalReview: 'AgreementsInternalReview',
    ExternalReview: 'AgreementsExternalReview',
    Rename: 'AgreementsRename',
    Share: 'AgreementsShareLink'
});

function AgreementActionManager(anchor, namespace) {
    this.anchor = anchor;
    this.namespace = namespace;
    this.activeScope = null;   
}

AgreementActionManager.prototype.getAgreements = function(component, sourceId) {
    var action = component.get('c.getAgreements');

    return new Promise((resolve, reject) =>{
      action.setParams({
        sourceObjectId: sourceId
      });
      action.setCallback(this,(response) => {
        var state = response.getState();
        if (state === "SUCCESS") {
          resolve(response.getReturnValue());
        } else if (state === "ERROR") {
          reject(response.getErrors());
        }
      });
      $A.enqueueAction(action);
    });
}
/**
FIXME:
Essentially the same operation we would need to do on the Server side. 
So creating this in the interim until we can retrieve an agreement by id from the API
**/
AgreementActionManager.prototype.getAgreement = function(agreementId, sourceId, component) {
  var getAgreements = this.getAgreements;
  return new Promise((resolve, reject) => {
    getAgreements(component, sourceId).then((agreements) => {
      var filtered = agreements.find(agreement => agreement.id.value.toLowerCase() === agreementId.toLowerCase());
      if (filtered) resolve(filtered);
      else reject('Agreement doesnt exist');
    }).catch(err => reject(err));
  });
}

AgreementActionManager.prototype.getComponentName = function(name) {
    return this.namespace + ':' + name;
}

AgreementActionManager.prototype.upload = function(component) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.Upload), {
        showModal: true
    }).then(modalComponent => {
        this.activeScope = modalComponent;
    });
}

AgreementActionManager.prototype.delete = function(agreementDetails, component) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.Delete), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(modalComponent => {
        this.activeScope = modalComponent;
    });
}

AgreementActionManager.prototype.rename = function(agreementDetails, component) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.Rename), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(modalComponent => {
        this.activeScope = modalComponent;
    });
}

AgreementActionManager.prototype.internalReview = function(agreementDetails, component) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.InternalReview), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(modalComponent => {
        this.activeScope = modalComponent;
    });
}

AgreementActionManager.prototype.externalReview = function(agreementDetails, component) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.ExternalReview), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(modalComponent => {
        this.activeScope = modalComponent;
    });
}

AgreementActionManager.prototype.share = function(agreementDetails, component) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.Share), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(modalComponent => {
        this.activeScope = modalComponent;
    });
}

window.AgreementActionManager = AgreementActionManager;