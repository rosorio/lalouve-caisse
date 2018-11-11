var el = document.getElementById("tmpl_header_right");
el.innerHTML += '<button type="button" onclick="if (confirm(\'Fermer la caisse ?\')) { window.location=\'http://127.0.0.1:8080/stopkiosk\'; }">Fermer la caisse</button>';
