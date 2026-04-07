// App.js - Authentication & Global Logic

// Handle Theme Toggling
function toggleMode() {
    document.body.classList.toggle('dark-mode');
    const isDark = document.body.classList.contains('dark-mode');
    localStorage.setItem('theme', isDark ? 'dark' : 'light');
}

// Load Theme on Init
(function() {
    if(localStorage.getItem('theme') === 'dark') {
        document.body.classList.add('dark-mode');
    }
})();

// Signup Logic
function signup() {
    let name = document.getElementById("name").value;
    let email = document.getElementById("email").value;
    let password = document.getElementById("password").value;

    if (!name || !email || !password) {
        Swal.fire({
            icon: 'warning',
            title: 'Missing Fields',
            text: 'Please fill out all registration fields.',
            confirmButtonColor: 'hsl(221, 83%, 53%)'
        });
        return;
    }

    let user = { name, email, password };
    localStorage.setItem("user", JSON.stringify(user));

    Swal.fire({
        icon: 'success',
        title: 'Account Created',
        text: 'Welcome to Urban Noise Intelligence',
        showConfirmButton: false,
        timer: 1500
    }).then(() => {
        window.location.href = "login.html";
    });
}

// Login Logic
function login() {
    let email = document.getElementById("email").value;
    let password = document.getElementById("password").value;

    let storedUser = JSON.parse(localStorage.getItem("user"));

    if (storedUser && email === storedUser.email && password === storedUser.password) {
        Swal.fire({
            icon: 'success',
            title: 'Login Successful',
            showConfirmButton: false,
            timer: 1000
        }).then(() => {
            window.location.href = "dashboard.html";
        });
    } else {
        Swal.fire({
            icon: 'error',
            title: 'Access Denied',
            text: 'Invalid credentials. Please try again.',
            confirmButtonColor: 'hsl(348, 83%, 47%)'
        });
    }
}

// Logout Logic
function logout() {
    Swal.fire({
        title: 'Sign Out?',
        text: "You will be securely logged out.",
        icon: 'warning',
        showCancelButton: true,
        confirmButtonColor: 'hsl(348, 83%, 47%)',
        cancelButtonColor: 'hsl(215, 16%, 47%)',
        confirmButtonText: 'Yes, log out!'
    }).then((result) => {
        if (result.isConfirmed) {
            localStorage.removeItem("user");
            window.location.href = "login.html";
        }
    });
}