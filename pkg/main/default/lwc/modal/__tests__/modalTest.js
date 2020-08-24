import { createElement } from 'lwc';
import Modal from 'c/modal';

describe('c-modal', () => {
  afterEach(() => {
     while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('Header is displayed and Header slot is hidden', () => {
    const HEADER = 'The modal header';
    const element = createElement('c-modal', {
      is: Modal
    });
    //setting @api attributes
    element.header = HEADER;
    element.showModal = true;
    document.body.appendChild(element);

    const headerEl = element.shadowRoot.querySelector(
      'h2[class="slds-text-heading_medium slds-hyphenate ds-modal-header-title"]'
    );
    expect(headerEl.textContent).toBe(HEADER);

    const headerSlotEl = element.shadowRoot.querySelector(
      'slot[name="header"]'
    );
    expect(headerSlotEl).toBeNull();
  });

  it('Header slot is displayed when header label is not set', () => {
    const element = createElement('c-modal', {
      is: Modal
    });
    element.showModal = true;
    document.body.appendChild(element);

    // Return a promise to wait for any asynchronous DOM updates.
    return Promise.resolve().then(() => {
      const headerSlotEl = element.shadowRoot.querySelector(
        'slot[name="header"]'
      );
      expect(headerSlotEl).not.toBeNull();
    });
  });

  it('Modal is hidden as default', () => {
    const element = createElement('c-modal', {
      is: Modal
    });
    document.body.appendChild(element);

    const modalContainerElement = element.shadowRoot.querySelector(
      '.slds-modal__container'
    );
    expect(modalContainerElement).toBeNull();
  });

  it('Modal CSS class updates based on public property changes', () => {
    const element = createElement('c-modal', {
      is: Modal
    });
    document.body.appendChild(element);
    element.showModal = true;

    return Promise.resolve()
      .then(() => {
        const modalContainerElementShow = element.shadowRoot.querySelector(
          '.slds-modal__container'
        );
        expect(modalContainerElementShow.tagName).toBe('DIV');
        element.showModal = false;
      })
      .then(() => {
        const modalContainerElementHide = element.shadowRoot.querySelector(
          '.slds-modal__container'
        );
        expect(modalContainerElementHide).toBeNull();
      });
  });

  it('Modal closes on click on close icon', () => {
    const handler = jest.fn();
    const element = createElement('c-modal', {
      is: Modal
    });
    element.addEventListener('close', handler);
    element.showModal = true;
    document.body.appendChild(element);

    const closeIcon = element.shadowRoot.querySelector(
      '.slds-modal__close'
    );
    closeIcon.dispatchEvent(new CustomEvent('click'));

    return Promise.resolve()
      .then(() => {
        expect(handler).toHaveBeenCalled();
      })
  });

  it('Enable modal on modal and test the respective css class shows up', () => {
    const element = createElement('c-modal', {
      is: Modal
    });
    element.showModal = true;
    element.modalOnModal = true;
    document.body.appendChild(element);
    const modalSectionElement = element.shadowRoot.querySelector(
      '.slds-modal_medium'
    );
    expect(modalSectionElement).not.toBeNull();
  });

  it('Enable modal size and test the respective css class shows up', () => {
    const element = createElement('c-modal', {
      is: Modal
    });
    element.showModal = true;
    element.modalSize = 'large';
    document.body.appendChild(element);
    const modalSectionElement = element.shadowRoot.querySelector(
      '.slds-modal_large'
    );
    expect(modalSectionElement).not.toBeNull();
  });
});