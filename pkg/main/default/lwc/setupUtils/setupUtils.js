import envelopeConfiguration from '@salesforce/label/c.EnvelopeTemplateUpperCase';
import documents from '@salesforce/label/c.Documents';
import recipients from '@salesforce/label/c.Recipients';
import mergeFields from '@salesforce/label/c.MergeFields';
import tagger from '@salesforce/label/c.Tagger';
import options from '@salesforce/label/c.Options';
import customButton from '@salesforce/label/c.PublishStep';
import errorLabel from '@salesforce/label/c.Error';
import nameLabel from '@salesforce/label/c.NameLabel';
import renameEnvelopeConfiguration from '@salesforce/label/c.RenameEnvelopeConfiguration';
import saveAndClose from '@salesforce/label/c.SaveAndClose';
import saveAndFinish from '@salesforce/label/c.SaveAndFinish';
import back from '@salesforce/label/c.Back';
import next from '@salesforce/label/c.Next';
import save from '@salesforce/label/c.Save';
import cancel from '@salesforce/label/c.Cancel';

const LABEL = {
  envelopeConfiguration : envelopeConfiguration,
  documents : documents,
  recipients : recipients,
  mergeFields : mergeFields,
  tagger : tagger,
  options : options,
  customButton : customButton,
  errorLabel : errorLabel,
  nameLabel : nameLabel,
  renameEnvelopeConfiguration : renameEnvelopeConfiguration,
  saveAndClose : saveAndClose,
  saveAndFinish : saveAndFinish,
  back : back,
  next : next,
  save : save,
  cancel : cancel
}

export {
  LABEL
}