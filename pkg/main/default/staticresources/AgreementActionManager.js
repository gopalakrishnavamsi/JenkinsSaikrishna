var generateComponent = function (anchor, component, componentName, attributes) {
  return new Promise((resolve, reject) => {
    try {
      if (!anchor || !component || !componentName || !attributes) reject('invalid parameters');
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
            reject('cant find container');
          }
        }
      );
    } catch (err) {
      reject('error generating component: ' + err);
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

AgreementActionManager.prototype.getAgreement = function (component, agreementId) {
  var action = component.get('c.getAgreement');

  return new Promise((resolve, reject) => {
    action.setParams({
      agreementId: agreementId
    });
    action.setCallback(this, (response) => {
      var state = response.getState();
      if (state === "SUCCESS") {
        resolve(response.getReturnValue());
      } else if (state === "ERROR") {
        reject(response.getError());
      }
    });
    $A.enqueueAction(action);
  });
};

AgreementActionManager.prototype.getComponentName = function (name) {
  return this.namespace + ':' + name;
};

AgreementActionManager.prototype.upload = function (component) {
  if (this.activeScope) this.activeScope.destroy();
  generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.Upload), {
    showModal: true
  }).then(modalComponent => {
    this.activeScope = modalComponent;
  }).catch(err => {
    throw err;
  });
};

AgreementActionManager.prototype.delete = function (agreementDetails, component) {
  if (this.activeScope) this.activeScope.destroy();
  generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.Delete), {
    showModal: true,
    agreementDetails: agreementDetails
  }).then(modalComponent => {
    this.activeScope = modalComponent;
  }).catch(err => {
    throw err;
  });
};

AgreementActionManager.prototype.rename = function (agreementDetails, component) {
  if (this.activeScope) this.activeScope.destroy();
  generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.Rename), {
    showModal: true,
    agreementDetails: agreementDetails
  }).then(modalComponent => {
    this.activeScope = modalComponent;
  }).catch(err => {
    throw err;
  });
};

AgreementActionManager.prototype.internalReview = function (agreementDetails, component) {
  if (this.activeScope) this.activeScope.destroy();
  generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.InternalReview), {
    showModal: true,
    agreementDetails: agreementDetails
  }).then(modalComponent => {
    this.activeScope = modalComponent;
  }).catch(err => {
    throw err;
  });
};

AgreementActionManager.prototype.externalReview = function (agreementDetails, component) {
  if (this.activeScope) this.activeScope.destroy();
  generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.ExternalReview), {
    showModal: true,
    agreementDetails: agreementDetails
  }).then(modalComponent => {
    this.activeScope = modalComponent;
  }).catch(err => {
    throw err;
  });
};

AgreementActionManager.prototype.share = function (agreementDetails, component) {
  if (this.activeScope) this.activeScope.destroy();
  generateComponent(this.anchor, component, this.getComponentName(AgreementComponents.Share), {
    showModal: true,
    agreementDetails: agreementDetails
  }).then(modalComponent => {
    this.activeScope = modalComponent;
  }).catch(err => {
    throw err;
  });
};

window.AgreementActionManager = AgreementActionManager;