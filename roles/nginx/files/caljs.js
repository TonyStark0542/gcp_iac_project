let calculation = localStorage.getItem('calculationVal') || '';

displayCalculation();

document.querySelector('.js-calculation').addEventListener('keydown', function (event) {
  const allowedCharacters = /[0-9\+\-\*\/\.\%]/;
  const key = event.key;

  
  if (!allowedCharacters.test(key) && key !== "Backspace") {
    
    event.preventDefault();
  }
});


function updateCal(value) {
  const allowedCharacters = /[0-9\+\-\*\/\.\%]/;

  if (allowedCharacters.test(value)){
    calculation += value;

    displayCalculation();

    localStorage.setItem('calculationVal', calculation);
  }
  
}

function displayCalculation() {
  document.querySelector('.js-calculation').value = calculation;
}

function plusOrminus(){
  let nums = document.querySelector('.js-plus-minus').value;
  nums = Number(nums);
  
  if(nums > 0){
    document.querySelector('.js-plus-minus').value = -nums;
  }
  else if(nums < 0){
    document.querySelector('.js-plus-minus').value = Math.abs(nums);
  }
  else if(nums === 0){
    document.querySelector('.js-plus-minus').value = nums;
  }
  
}

function percentage(){
  let temp = document.querySelector('.js-percentage').value;
  temp = Number(temp);
  if(temp === 0){
    alert('Invaild format used.');
  }
  else{
    console.log(temp);
    temp = temp/100;
    console.log(temp);
    document.querySelector('.js-percentage').value = temp;
    calculation = String(temp);
    console.log(calculation);
    localStorage.setItem('calculationVal', calculation);
  }
}
