function uploadContent() {
  if (content !== textarea.value) {
    let temp = textarea.value;

    fetch(window.location.href, {
      headers: { "Content-Type": "application/x-www-form-urlencoded; charset=utf-8" },
      method: 'POST',
      body: "data="+encodeURIComponent(temp)
    })

    content = temp;
    setTimeout(uploadContent, 1000);

    printable.removeChild(printable.firstChild);
    printable.appendChild(document.createTextNode(temp));
  }
  else {
    setTimeout(uploadContent, 1000);
  }
}

const textarea = document.getElementById('content');
const end = textarea.value.length;
const printable = document.getElementById('printable');
let content = textarea.value;

printable.appendChild(document.createTextNode(content));
textarea.setSelectionRange(end, end);
textarea.focus();

uploadContent();
