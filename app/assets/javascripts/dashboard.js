document.addEventListener('DOMContentLoaded', function() {
  const toggleButton = document.getElementById('toggle-balance-button');
  const currentBalanceElement = document.getElementById('current-balance');
  
  const actualBalanceText = currentBalanceElement.innerHTML; 
  const maskedBalanceText = "Total em conta: ******";

  currentBalanceElement.innerHTML = maskedBalanceText; 
  currentBalanceElement.style.display = 'block';
  toggleButton.textContent = 'Ver Saldo';

  if (toggleButton && currentBalanceElement) {
    toggleButton.addEventListener('click', function() {
      // Se o saldo atual for o ****, mostra o real
      if (currentBalanceElement.innerHTML === maskedBalanceText) {
        currentBalanceElement.innerHTML = actualBalanceText; 
        toggleButton.textContent = 'Ocultar Saldo'; 
      } else {
        // Se o saldo atual for o real, mostra o ****
        currentBalanceElement.innerHTML = maskedBalanceText; 
        toggleButton.textContent = 'Ver Saldo';
      }
    });
  }
});