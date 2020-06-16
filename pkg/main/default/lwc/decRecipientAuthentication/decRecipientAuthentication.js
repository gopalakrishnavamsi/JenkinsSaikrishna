import {LightningElement, api} from 'lwc';
import {AuthenticationTypes, Labels, Types, Authentication} from 'c/recipientUtils';
import {isEmpty,proxify} from 'c/utils';

const dynamicTypes = new Set(
  [
    Types.RelatedRecipient.value,
    Types.LookupRecipient.value,
    Types.EntityLookup.value
  ]
);

export default class DecRecipientAuthentication extends LightningElement {
  AuthenticationTypes = AuthenticationTypes;
  Labels = Labels;

  privateType;

  privateValue = proxify(new Authentication({}));

  authenticationType;

  @api
  get value() {
    return this.privateValue;
  }

  set value(val) {
    this.privateValue = !isEmpty(val) ? proxify(val) : new Authentication({});
    this.authenticationType = !isEmpty(this.privateValue) ? this.privateValue.type : null;
  }

  @api
  get type() {
    return this.privateType;
  }

  set type(val) {
    this.privateType = val;
  }

  get options() {
    return Object.values(this.AuthenticationTypes);
  }

  get smsValue() {
    return this.value && this.value.smsPhoneNumbers && this.value.smsPhoneNumbers[0] ? this.value.smsPhoneNumbers[0] : null;
  }

  get isManualSMS() {
    return this.type ? !dynamicTypes.has(this.type) : false
  }

  get showSMS(){
    return this.isManualSMS && this.authenticationType === this.AuthenticationTypes.SMSOrPhone.value;
  }

  get showAccessCode() {
    return this.authenticationType === this.AuthenticationTypes.AccessCode.value;
  }

  get hasAuthentication() {
    return !isEmpty(this.value) && !isEmpty(this.value.type);
  }

  resetAuthentication = () => {
    this.value = null;
    this.dispatchEvent(
      new CustomEvent('authenticationchange', {
        detail: {
          isRemove: true
        }
      })
    )    
  }

  handleTypeChange = ({ target }) => {
    const value = target.value;
    this.authenticationType = value;
    this.dispatchEvent(
      new CustomEvent('authenticationchange', {
        detail: {
          type: value
        }
      })
    )
  }

  handleDataChange = ({ target }) => {
    const { name, value } = target;
    if (name === AuthenticationTypes.SMSOrPhone.value) this.value.phoneValue = [value];
    else if (name === AuthenticationTypes.AccessCode.value) this.value.accessCode = value;
    this.dispatchEvent(
      new CustomEvent('authenticationchange', {
        detail: {
          type: name,
          data: value
        }
      })
    )
  }
}
