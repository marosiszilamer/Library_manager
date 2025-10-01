
// --- Firebase Configuration ---
const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
};

// --- Initialize Firebase ---
firebase.initializeApp(firebaseConfig);
const auth = firebase.auth();
const firestore = firebase.firestore();

// --- DOM Elements ---
const loginBox = document.getElementById('loginBox');
const registerBox = document.getElementById('registerBox');
const contentContainer = document.getElementById('content-container');

const showRegisterBtn = document.getElementById('showRegister');
const showLoginBtn = document.getElementById('showLogin');

const loginForm = document.getElementById('loginForm');
const registerForm = document.getElementById('registerForm');

const logoutBtn = document.getElementById('logout-btn');
const userEmailSpan = document.getElementById('user-email');
const adminContent = document.getElementById('admin-content');
const userContent = document.getElementById('user-content');

// --- UI Toggling ---
showRegisterBtn.addEventListener('click', () => {
    loginBox.classList.add('hidden');
    registerBox.classList.remove('hidden');
});

showLoginBtn.addEventListener('click', () => {
    registerBox.classList.add('hidden');
    loginBox.classList.remove('hidden');
});

// --- Auth Logic ---

// Registration
registerForm.addEventListener('submit', (e) => {
    e.preventDefault();

    const email = document.getElementById('registerEmail').value;
    const password = document.getElementById('regPassword').value;
    const confirmPassword = document.getElementById('regConfirm').value;

    if (password !== confirmPassword) {
        alert("Passwords do not match!");
        return;
    }

    auth.createUserWithEmailAndPassword(email, password)
        .then(userCredential => {
            // Set default role for new users
            firestore.collection('users').doc(userCredential.user.uid).set({
                role: 'user'
            })
            .then(() => {
                alert("Registration successful!");
            });
        })
        .catch(error => {
            alert("Registration error: " + error.message);
        });
});

// Login
loginForm.addEventListener('submit', (e) => {
    e.preventDefault();

    const email = document.getElementById('loginEmail').value;
    const password = document.getElementById('loginPassword').value;

    auth.signInWithEmailAndPassword(email, password)
        .catch(error => {
            alert("Login error: " + error.message);
        });
});

// Logout
logoutBtn.addEventListener('click', () => {
    auth.signOut();
});


// --- Auth State Observer ---
auth.onAuthStateChanged(user => {
    if (user) {
        // User is logged in
        loginBox.classList.add('hidden');
        registerBox.classList.add('hidden');
        contentContainer.classList.remove('hidden');

        userEmailSpan.textContent = user.email;

        // Check user role
        const userDocRef = firestore.collection('users').doc(user.uid);
        userDocRef.get().then(doc => {
            if (doc.exists) {
                const userData = doc.data();
                if (userData.role === 'admin') {
                    adminContent.classList.remove('hidden');
                    userContent.classList.add('hidden');
                } else {
                    adminContent.classList.add('hidden');
                    userContent.classList.remove('hidden');
                }
            } else {
                // If no role is found, default to user
                userContent.classList.remove('hidden');
            }
        }).catch(error => {
            console.error("Error getting user role:", error);
        });

    } else {
        // User is logged out
        loginBox.classList.remove('hidden');
        contentContainer.classList.add('hidden');
        adminContent.classList.add('hidden');
        userContent.classList.add('hidden');
    }
});
