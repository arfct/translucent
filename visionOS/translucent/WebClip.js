 (function() {
   let isDragging = false;
   let dragPath = []; // Array to store the path of dragged elements
   
   let currentAncestor = null; // Track the common ancestor
   let lastElement = null; // Track the last element dragged over
   
   document.documentElement.classList.add('WebClipEdit');
   let cssTag = document.createElement('style');
   cssTag.id = "WebClipStyle"
   cssTag.innerHTML = `
    .WebClipToolbar {
    position: fixed;
    bottom: 20px;
    z-index: 1000;
    margin:auto;
    width:320px;
    display:flex;
    gap:8px;
    justify-content: center;;
    }
    
    .WebClipToolbar button {
    background-color: #fff9;
    padding: 10px 20px;
    border-radius: 5px;
    cursor: pointer;
    border:none;
    border-radius:100px;
    font-size:18px;
    }
    
    .WebClipShadow {
    box-shadow:
    0 14px 28px rgba(0,0,0,0.25),
    0 10px 10px rgba(0,0,0,0.22),
    inset 1px 1px 0px 0px #fff8,
    inset -1px -1px 0px 0px #fff4,
    inset 0 0 50px 50px #fff4,
    0 0 0 1px #0005,
    0 0 0 4000px #0003;
    box-sizing:border-box;
    top:-100px;
    left:-100px;
    position: fixed;
    pointer-events: none;
    border-radius:13px;
    }
    
    html:not(.WebClipEdit) .WebClipShadow,
    html:not(.WebClipEdit) .WebClipToolbar {
    display:none;
    }
    
    
    html.WebClip * { visibility:hidden; }
    html.WebClip [data-webclip="true"] * { visibility: visible !important; }
    html.WebClip [data-webclip="true"] {
    position:fixed;
    top:0;
    left:0;
    bottom:0;
    right:0;
    transform:none;
    visibility:visible !important;
    opacity:1.0 !important;
    background:transparent !important;
    }
    
    
    `
   document.head.appendChild(cssTag);
   
   
   document.getElementById('WebClipApply').addEventListener('click', function() {
     currentAncestor.dataset.webclip = 'true';
     document.documentElement.classList.add('WebClip');
     document.documentElement.classList.remove('WebClipEdit');
     const rect = currentAncestor.getBoundingClientRect();
     window.widget?.postMessage(JSON.stringify({
     type: 'webclip',
     rect: {
     selector: selector,
     width: rect.width,
     height: rect.height
     }
     }));
     
   });
   document.getElementById('WebClipCancel').addEventListener('click', function() {
     document.documentElement.classList.remove('WebClipEdit');
   });
   
   function onMouseDown(e) {
     if (e.target.closest(".WebClipToolbar")) return;
     isDragging = true;
     dragPath = [];
     document.addEventListener('mousemove', onMouseMove);
     document.addEventListener('mouseup', onMouseUp);
     onMouseMove(e);
   }
   
   function onMouseMove(e) {
     
     if (!isDragging) return;
     
     const x = e.clientX, y = e.clientY;
     const elementUnderCursor = document.elementFromPoint(x, y);
     
     if (elementUnderCursor && lastElement !== elementUnderCursor) {
       if (dragPath.includes(elementUnderCursor)) {
         // Remove elements from dragPath until we hit the current target again
         while (dragPath.length && dragPath[dragPath.length - 1] !== elementUnderCursor) {
           const removedElement = dragPath.pop();
           removedElement.classList.remove('illuminated');
         }
       } else {
         elementUnderCursor.classList.add('illuminated');
         dragPath.push(elementUnderCursor);
       }
       
       lastElement = elementUnderCursor;
       updateCommonAncestorHighlight();
     }
   }
   
   function onMouseUp() {
     isDragging = false;
     dragPath.forEach(el => el.classList.remove('illuminated'));
     document.removeEventListener('mousemove', onMouseMove);
     document.removeEventListener('mouseup', onMouseUp);
     
     dragPath = [];
     lastElement = null;
   }
   
   function updateCommonAncestorHighlight() {
     if (dragPath.length < 1) return;
     
     let commonAncestor = dragPath[0];
     dragPath.forEach(element => {
       commonAncestor = findCommonAncestor(commonAncestor, element);
     });
     
     while (commonAncestor.getBoundingClientRect().height < 120) {
       commonAncestor = commonAncestor.parentElement;
     }
     
     if (currentAncestor !== commonAncestor) {
       if (currentAncestor) currentAncestor.classList.remove('enlightened');
       commonAncestor.classList.add('enlightened');
       currentAncestor = commonAncestor;
       
       if (currentAncestor) {
         const rect = currentAncestor.getBoundingClientRect();
         const shadow = document.querySelector('.WebClipShadow');
         shadow.style.left = rect.left + 'px';
         shadow.style.top = rect.top + 'px';
         shadow.style.width = rect.width + 'px';
         shadow.style.height = rect.height + 'px';
       }
     }
   }
   
   function findCommonAncestor(el1, el2) {
     const parents1 = getParents(el1);
     const parents2 = getParents(el2);
     for (let parent1 of parents1) {
       if (parents2.includes(parent1)) return parent1;
     }
     
     return document.body;
   }
   
   function getParents(el) {
     let parents = [];
     while (el) {
       parents.push(el);
       el = el.parentElement;
     }
     return parents;
   }
   
   document.addEventListener('mousedown', onMouseDown);
 })();
