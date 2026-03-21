  let navPath = '/nav.html';

  // Load the nav.html content
  fetch(navPath)
    .then(response => response.text())
    .then(data => {
      document.getElementById('navbar').innerHTML = data;
    })
    .catch(err => {
      console.warn("Could not load nav.html. If running locally without a server, fetch may not work.", err);
    });