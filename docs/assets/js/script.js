const body = document.querySelector("body");
const updateColor = () => {
  const currentTime = Math.floor(Date.now() / 1000); // seconds since 1970
  const hue = currentTime % 360;
  
  document.documentElement.style = `
  --hue: ${hue};
  `
  body.style.background = 
  `linear-gradient(to bottom right, 
  hsl(${hue}, 33%, 25%), 
  hsl(${hue}, 15%, 10%), 
  #000)`;
}
updateColor()
setInterval(updateColor, 1000);

const tiltableElement = document.querySelector(".tiltableElement");
document.addEventListener("mousemove", (event) => {
  const x = event.clientX;
  const y = event.clientY;
  const tiltX = (window.innerWidth / 2 - x) / 20;
  const tiltY = (window.innerHeight / 2 - y) / 20;
  tiltableElement.style.transform = `rotateX(${tiltY}deg) rotateY(${-tiltX}deg)`;
});
body.style.perspective = "1000px";
