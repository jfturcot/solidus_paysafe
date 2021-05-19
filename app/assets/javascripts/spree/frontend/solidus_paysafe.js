// Placeholder manifest file.
// the installer will append this file to the app vendored assets here: vendor/assets/javascripts/spree/frontend/all.js'
document.addEventListener('DOMContentLoaded', _event => {
  const paysafeScript = document.createElement('script');
  paysafeScript.src = 'https://hosted.paysafe.com/js/v1/latest/paysafe.min.js';
  paysafeScript.async = false;
  document.head.appendChild(paysafeScript);
});

window.addEventListener('load', _event => {
  const paysafeSetup = document.getElementById('paysafe-setup');
  if (paysafeSetup) {
    const form = paysafeSetup.closest('form');

    window.paysafe.fields.setup(
      paysafeSetup.dataset.token,
      {
        environment: paysafeSetup.dataset.environment,
        fields: {
          cardNumber: {
            selector: "#card_number",
            placeholder: "XXXX XXXX XXXX XXXX"
          },
          expiryDate: {
            selector: "#card_expiry",
            placeholder: "XX/XX"
          },
          cvv: {
            selector: "#card_code",
            placeholder: "XXX"
          }
        },
        style: {

        }
      },
      function(instance, error) {
        if (error) {
          console.log(error)
        } else {
          form.onsubmit = (event) => {
            event.preventDefault();

            instance.tokenize(
              (_instance, error, result) => {
                if (error) {
                  console.log(error);
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
});

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
