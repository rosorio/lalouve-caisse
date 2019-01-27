var el = document.getElementsByClassName("o_database_list")[0];
el.innerHTML += '<center><br><br><p><button type="button" onclick="if (confirm(\'Fermer la caisse ?\')) { window.location=\'http://127.0.0.1:8080/stopkiosk\'; }">Fermer la caisse</button></p></center>';
