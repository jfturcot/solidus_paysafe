// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/frontend/all.js'
document.addEventListener('DOMContentLoaded', _event => {
  const paysafeScript = document.createElement('script');
  paysafeScript.src = 'https://hosted.paysafe.com/js/v1/latest/paysafe.min.js';
  paysafeScript.async = false;
  document.head.appendChild(paysafeScript);
});

const loadEvent = window.Turbolinks ? 'turbolinks:load' : 'load';

window.addEventListener(loadEvent, _event => {
  const paysafeSetup = document.getElementById('paysafe-setup');
  if (paysafeSetup) {
    const form = paysafeSetup.closest('form');
    if (form) {
      const errorElement = form.querySelector('#card-errors');
      const submitButton = form.querySelector('input[type=submit]') || form.querySelector('button[type=submit]');

      window.paysafe.fields.setup(
        paysafeSetup.dataset.token,
        {
          environment: paysafeSetup.dataset.environment,
          fields: {
            cardNumber: {
              selector: '#card_number',
              placeholder: paysafeSetup.dataset.cardNumberPlaceholder || '0000 0000 0000 0000'
            },
            expiryDate: {
              selector: '#card_expiry',
              placeholder: paysafeSetup.dataset.expiryDatePlaceholder || 'MM / YY'
            },
            cvv: {
              selector: '#card_code',
              placeholder: paysafeSetup.dataset.cvvPlaceholder || '000'
            }
          },
          style: {
            // TODO: Add support for custom styling
          }
        },
        (instance, error) => {
          if (error) {
            showError(new CustomEvent('error', { detail: error }), paysafeSetup, errorElement, submitButton);
          } else {
            form.onsubmit = (event) => {
              event.preventDefault();

              if (errorElement && submitButton) {
                errorElement.style.display = 'none';
                errorElement.innerText = '';
                submitButton.disabled = true;
              }

              instance.tokenize(
                (_instance, tokenError, result) => {
                  if (tokenError) {
                    showError(
                      new CustomEvent('error', { detail: tokenError }), paysafeSetup, errorElement, submitButton
                    );
                  } else {
                    form.querySelector('input#cc_type').value = mapCC(instance.getCardBrand());
                    form.querySelector('input#encrypted_data').value = result.token;

                    form.submit();
                  }
                }
              )
            }
          }
        }
      );
    }
  }
});

const showError = (errorEvent, paysafeSetup, errorElement, submitButton) => {
  paysafeSetup.dispatchEvent(errorEvent);

  if (errorElement && submitButton) {
    errorElement.innerText = errorEvent.detail.displayMessage;
    errorElement.style.display = 'block';

    setTimeout(
      () => submitButton.disabled = false
      , 100
    );
  }
}

const mapCC = (ccType) => {
    if (ccType === 'MasterCard' || ccType === 'mastercard') {
    return 'mastercard';
  } else if (ccType === 'Visa' || ccType === 'visa') {
    return 'visa';
  } else if (ccType === 'American Express' || ccType === 'amex') {
    return 'amex';
  } else if (ccType === 'Discover' || ccType === 'discover') {
    return 'discover';
  } else if (ccType === 'Diners Club' || ccType === 'diners') {
    return 'dinersclub';
  } else if (ccType === 'JCB' || ccType === 'jcb') {
    return 'jcb';
  } else if (ccType === 'Unionpay' || ccType === 'unionpay') {
    return 'unionpay';
  }
}
