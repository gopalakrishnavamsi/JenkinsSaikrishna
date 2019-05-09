var generateComponent = function(anchor, componentName, attributes) {
    return new Promise((resolve, reject) => {
        try {
            $A.createComponent(
                componentName,
                attributes,
                (result, err, msg) => {
                    if (err && msg) reject(msg);
                    var container = component.find(anchor);
                    if (container.isValid()) {
                        var body = container.get('v.body');
                        body.push(result);
                        container.set('v.body', body);
                        resolve(result);
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
    Rename: 'AgreementsRename'
});

function AgreementActionManager(anchor, component, namespace) {
    this.anchor = anchor;
    this.component = component;
    this.namespace = namespace;
    this.activeScope = null;   
}

AgreementActionManager.prototype.getComponentName = function(name) {
    return this.namespace + name;
}

AgreementActionManager.prototype.upload = function(agreementDetails) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, this.getComponentName(AgreementComponents.Upload), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(component => {
        this.activeScope = component;
    });
}

AgreementActionManager.prototype.delete = function(agreementDetails) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, this.getComponentName(AgreementComponents.Delete), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(component => {
        this.activeScope = component;
    });
}

AgreementActionManager.prototype.rename = function(agreementDetails) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, this.getComponentName(AgreementComponents.Rename), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(component => {
        this.activeScope = component;
    });
}

AgreementActionManager.prototype.internalReview = function(agreementDetails) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, this.getComponentName(AgreementComponents.InternalReview), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(component => {
        this.activeScope = component;
    });
}

AgreementActionManager.prototype.externalReview = function(agreementDetails) {
    if (this.activeScope) this.activeScope.destroy();
    generateComponent(this.anchor, this.getComponentName(AgreementComponents.ExternalReview), {
        showModal: true,
        agreementDetails: agreementDetails
    }).then(component => {
        this.activeScope = component;
    });
}

/**
  ES6 Version of AgreementActionManager

class AgreementActionManager {
    construtor(anchor, component,namespace = 'c') {
      this.anchor = anchor;
      this.namespace = namespace;
      this.activeScope = null;
      this.component = component;
    }

    getComponentName(name) {
      return `${this.namespace}${name}`;
    }

    upload() {
      if (this.activeScope) this.activeScope.destroy();
      generateComponent(this.anchor, this.getComponentName(AgreementComponents.Upload), {
        showModal: true
      }).then(component => {
        this.activeScope = component;
      });
    } 

    delete() {
      if (this.activeScope) this.activeScope.destroy();
      generateComponent(this.anchor, this.getComponentName(AgreementComponents.Delete), {
        showModal: true
      }).then(component => {
        this.activeScope = component;
      });
    } 

    rename(agreementDetails) {
      if (this.activeScope) this.activeScope.destroy();
      generateComponent(this.anchor, this.getComponentName(AgreementComponents.Rename), {
        showModal: true,
        agreementDetails: agreementDetails
      }).then(component => {
        this.activeScope = component;
      });
    }    

    internalReview(agreementDetails) {
      if (this.activeScope) this.activeScope.destroy();
      generateComponent(this.anchor, this.getComponentName(AgreementComponents.InternalReview), {
        showModal: true,
        agreementDetails: agreementDetails
      }).then(component => {
        this.activeScope = component;
      });
    }

    externalReview(agreementDetails) {
      if (this.activeScope) this.activeScope.destroy();
      generateComponent(this.anchor, this.getComponentName(AgreementComponents.ExternalReview), {
        showModal: true,
        agreementDetails: agreementDetails
      }).then(component => {
        this.activeScope = component;
      });
    }
}
**/

window.AgreementActionManager = AgreementActionManager;