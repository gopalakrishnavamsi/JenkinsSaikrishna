import { createElement } from 'lwc';
import DecDocuments from 'c/decDocuments';

describe('c-dec-documents', () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it('sample test', () => {
    // Create element
    const element = createElement('c-dec-documents', {
      is: DecDocuments
    });
    document.body.appendChild(element);

    // todo: will be adding correct unit tests
    expect(1).toBe(1);
  });
});