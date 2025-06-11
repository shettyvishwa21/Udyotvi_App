package com.example.udyothvi

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.Image
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.ContextCompat
import androidx.core.util.PatternsCompat
import com.example.udyothvi.ui.theme.UdyothviTheme
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.android.gms.common.api.ApiException
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import androidx.compose.foundation.shape.RoundedCornerShape
import com.google.android.gms.auth.api.signin.GoogleSignInAccount
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import retrofit2.HttpException
import java.io.IOException

class LoginActivity : ComponentActivity() {

    private lateinit var googleSignInClient: GoogleSignInClient
    private lateinit var googleSignInLauncher: androidx.activity.result.ActivityResultLauncher<Intent>
    private lateinit var sharedPreferences: SharedPreferences
    private val permissionLauncher = registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
        if (isGranted) {
            Log.d("GOOGLE", "GET_ACCOUNTS permission granted")
            initiateGoogleSignIn()
        } else {
            Log.w("GOOGLE", "GET_ACCOUNTS permission denied")
            Toast.makeText(this, "Permission denied. Cannot access Google accounts.", Toast.LENGTH_LONG).show()
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setupGoogleSignIn()

        setContent {
            UdyothviTheme(darkTheme = false) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color.White
                ) {
                    LoginScreen(
                        onLoginClick = { email, password ->
                            CoroutineScope(Dispatchers.Main).launch {
                                performLogin(email, password)
                            }
                        },
                        onGoogleSignInClick = {
                            if (ContextCompat.checkSelfPermission(
                                    this@LoginActivity,
                                    android.Manifest.permission.GET_ACCOUNTS
                                ) == PackageManager.PERMISSION_GRANTED
                            ) {
                                initiateGoogleSignIn()
                            } else {
                                permissionLauncher.launch(android.Manifest.permission.GET_ACCOUNTS)
                            }
                        },
                        onRegisterClick = {
                            startActivity(Intent(this@LoginActivity, RegistrationActivity::class.java))
                        }
                    )
                }
            }
        }
    }

    private fun setupGoogleSignIn() {
        sharedPreferences = getSharedPreferences("UdyothviPrefs", Context.MODE_PRIVATE)
        sharedPreferences.edit().clear().apply()

        val googleApiAvailability = GoogleApiAvailability.getInstance()
        val playServicesStatus = googleApiAvailability.isGooglePlayServicesAvailable(this)
        if (playServicesStatus != ConnectionResult.SUCCESS) {
            Log.e("GOOGLE", "Google Play Services error: code=$playServicesStatus")
            Toast.makeText(this, "Google Play Services unavailable (Code: $playServicesStatus)", Toast.LENGTH_LONG).show()
            googleApiAvailability.getErrorDialog(this, playServicesStatus, 0)?.show()
            return
        }

        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestEmail()
            .build()
        googleSignInClient = GoogleSignIn.getClient(this, gso)

        googleSignInClient.signOut().addOnCompleteListener {
            Log.d("GOOGLE", "Cleared cached Google Sign-In account")
        }

        setupGoogleSignInLauncher()
    }

    private fun setupGoogleSignInLauncher() {
        googleSignInLauncher =
            registerForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
            if (result.resultCode == RESULT_OK) {
                val task = GoogleSignIn.getSignedInAccountFromIntent(result.data)
                try {
                    val account = task.getResult(ApiException::class.java)
                    Log.d("GOOGLE", "Google Sign-In account: ${account?.email}")
                    account?.let { handleGoogleSignIn(it) } ?: run {
                        Log.e("GOOGLE", "Google Sign-In failed: No account returned")
                        Toast.makeText(this, "Google sign-in failed: No account selected", Toast.LENGTH_LONG).show()
                    }
                } catch (e: ApiException) {
                    Log.e("GOOGLE", "Google Sign-In failed: ${e.statusCode} - ${e.message}", e)
                    Toast.makeText(this, "Google sign-in failed: ${e.message}", Toast.LENGTH_LONG).show()
                    googleSignInClient.signOut().addOnCompleteListener {
                        Log.d("GOOGLE", "Signed out after Google Sign-In failure")
                    }
                }
            } else {
                Log.w("GOOGLE", "Google Sign-In cancelled or failed: resultCode=${result.resultCode}")
                Toast.makeText(this, "Google sign-in cancelled or failed", Toast.LENGTH_LONG).show()
                googleSignInClient.signOut().addOnCompleteListener {
                    Log.d("GOOGLE", "Signed out after Google Sign-In cancellation")
                }
            }
        }
    }

    private fun initiateGoogleSignIn() {
        val signInIntent = googleSignInClient.signInIntent
        if (signInIntent.resolveActivity(packageManager) != null) {
            Log.d("GOOGLE", "Launching Google Sign-In intent")
            googleSignInLauncher.launch(signInIntent)
        } else {
            Log.e("GOOGLE", "No activity can handle sign-in intent")
            Toast.makeText(this, "Cannot launch Google Sign-In", Toast.LENGTH_LONG).show()
        }
    }

    @Composable
    fun LoginScreen(
        onLoginClick: (String, String) -> Unit,
        onGoogleSignInClick: () -> Unit,
        onRegisterClick: () -> Unit
    ) {
        var email by remember { mutableStateOf("") }
        var emailError by remember { mutableStateOf("") }
        var password by remember { mutableStateOf("") }
        var passwordVisible by remember { mutableStateOf(false) }
        var keepMeSignedIn by remember { mutableStateOf(true) }
        var isLoading by remember { mutableStateOf(false) }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text("Welcome back!", fontSize = 26.sp, fontWeight = FontWeight.Bold, color = Color.Black)
            Spacer(modifier = Modifier.height(30.dp))

            OutlinedTextField(
                value = email,
                onValueChange = {
                    email = it
                    emailError = if (PatternsCompat.EMAIL_ADDRESS.matcher(it).matches() || it.matches(Regex("\\d+"))) "" else "Invalid email or phone"
                },
                label = { Text("Email or Phone", color = Color.Black) },
                modifier = Modifier.fillMaxWidth(),
                textStyle = LocalTextStyle.current.copy(color = Color.Black),
                isError = emailError.isNotEmpty(),
                singleLine = true
            )
            if (emailError.isNotEmpty()) {
                Text(text = emailError, color = Color.Red, fontSize = 12.sp, modifier = Modifier.align(Alignment.Start).padding(top = 4.dp))
            }

            Spacer(modifier = Modifier.height(20.dp))

            OutlinedTextField(
                value = password,
                onValueChange = { password = it },
                label = { Text("Password", color = Color.Black) },
                modifier = Modifier.fillMaxWidth(),
                textStyle = LocalTextStyle.current.copy(color = Color.Black),
                visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                trailingIcon = {
                    Icon(
                        imageVector = if (passwordVisible) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                        contentDescription = if (passwordVisible) "Hide password" else "Show password",
                        modifier = Modifier.clickable { passwordVisible = !passwordVisible }.padding(4.dp),
                        tint = Color.Black
                    )
                },
                singleLine = true
            )

            Spacer(modifier = Modifier.height(10.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Checkbox(checked = keepMeSignedIn, onCheckedChange = { keepMeSignedIn = it })
                    Text("Keep me signed in", color = Color.Black)
                }
                Text(
                    text = "Forgot Password?",
                    color = Color.Blue,
                    modifier = Modifier.clickable {
                        startActivity(Intent(this@LoginActivity, ForgotPasswordActivity::class.java))
                    }
                )
            }

            Spacer(modifier = Modifier.height(30.dp))

            Button(
                onClick = {
                    if (email.isNotEmpty() && password.isNotEmpty() && emailError.isEmpty()) {
                        isLoading = true
                        Log.d("LOGIN", "Attempting login with email: $email, password: $password")
                        onLoginClick(email, password)
                    } else {
                        Toast.makeText(this@LoginActivity, "Please enter valid email/phone and password", Toast.LENGTH_SHORT).show()
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(24.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF8A2BE2)),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text("Login", color = Color.White)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Button(
                onClick = onGoogleSignInClick,
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFF5F5F5)),
                border = BorderStroke(1.dp, Color.LightGray),
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(24.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Image(
                        painter = painterResource(id = R.drawable.google_logo),
                        contentDescription = "Google Icon",
                        modifier = Modifier
                            .size(24.dp)
                            .padding(end = 8.dp)
                    )
                    Text("Continue with Google", color = Color.Black, fontSize = 16.sp)
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text("New to Udyothvi?", color = Color.Black)
                Text(
                    text = "Click here",
                    color = Color.Blue,
                    modifier = Modifier.clickable(onClick = onRegisterClick)
                        .padding(start = 4.dp)
                )
            }
        }
    }

    private suspend fun performLogin(email: String, password: String) {
        Log.d("LOGIN", "Starting performLogin: email=$email, password=$password, isSsoUser=false")
        val apiService = RetrofitClient.apiService
        var isLoading by mutableStateOf(true)
        try {
            Log.d("API_CALL", "Attempting to connect to ${RetrofitClient.BASE_URL}")
            val trimmedEmail = email.trim().lowercase()
            val trimmedPassword = password.trim()
            val loginRequest = LoginRequest(
                email = trimmedEmail,
                password = trimmedPassword,
                isSsoUser = false
            )
            val requestJson = Gson().toJson(loginRequest)
            Log.d("LOGIN", "Raw JSON request: $requestJson")
            Log.d("LOGIN", "Sending request to ${RetrofitClient.BASE_URL}api/user/upsert")
            
            val response = apiService.validateAccount(loginRequest)
            Log.d("LOGIN", "Response: code=${response.code()}, headers=${response.headers()}")
            Log.d("LOGIN", "Response body: ${response.body()?.toString() ?: "null"}")

            if (response.isSuccessful) {
                val result = response.body()
                if (result != null) {
                    when (result.resultType) {
                        1 -> { // Success
                            val userData = result.resultData
                            if (userData != null) {
                                val userId = userData.userId
                                if (userId != null) {
                                    // Save user data
                    sharedPreferences.edit()
                                        .putString("user_email", userData.email ?: trimmedEmail)
                                        .putLong("user_id", userId ?: 0L)
                        .apply()

                                    // Show success message
                    Toast.makeText(this, result.resultMessage ?: "Login successful", Toast.LENGTH_SHORT).show()

                                    // Navigate to educational qualification
                                    val intent = Intent(this, EducationalQualificationActivity::class.java)
                                    startActivity(intent)
                                    finish()
                                } else {
                                    Toast.makeText(this, "Login failed: Invalid user ID", Toast.LENGTH_LONG).show()
                                }
                } else {
                                Toast.makeText(this, "Login failed: Invalid response data", Toast.LENGTH_LONG).show()
                            }
                        }
                        2 -> { // Account inactive
                            Toast.makeText(this, "Account is inactive. Please contact support.", Toast.LENGTH_LONG).show()
                        }
                        else -> { // Other error
                            Toast.makeText(this, result.resultMessage ?: "Login failed", Toast.LENGTH_LONG).show()
                        }
                    }
                } else {
                    Toast.makeText(this, "Invalid server response", Toast.LENGTH_LONG).show()
                }
            } else {
                val errorBody = response.errorBody()?.string()
                val errorMessage = try {
                    val errorResult = Gson().fromJson(errorBody, LoginResponse::class.java)
                    when (errorResult.resultType) {
                        0 -> "Invalid email/phone or password"
                        2 -> "Account is inactive"
                        else -> errorResult.resultMessage ?: "Login failed: ${response.code()}"
                    }
                } catch (e: Exception) {
                    "Login failed: ${response.code()}"
                }
                Toast.makeText(this, errorMessage, Toast.LENGTH_LONG).show()
                Log.w("LOGIN", "Failed with code ${response.code()}: $errorMessage")
            }
        } catch (e: Exception) {
            Log.e("LOGIN", "Exception in performLogin: ${e.message}", e)
            val errorMessage = when (e) {
                is HttpException -> "Server error: ${e.code()}"
                is IOException -> "Network error: ${e.message ?: "Unable to connect to server"}"
                else -> "Error: ${e.message ?: "Unknown error"}"
            }
            Toast.makeText(this, errorMessage, Toast.LENGTH_LONG).show()
        } finally {
            isLoading = false
        }
    }

    private fun handleGoogleSignIn(account: GoogleSignInAccount) {
        val email = account.email
        if (email.isNullOrEmpty()) {
            Log.e("GOOGLE", "Google Sign-In failed: No email provided")
            Toast.makeText(this, "Google sign-in failed: No email provided", Toast.LENGTH_LONG).show()
            googleSignInClient.signOut().addOnCompleteListener {
                Log.d("GOOGLE", "Signed out after invalid email")
            }
            return
        }

        CoroutineScope(Dispatchers.Main).launch {
            val trimmedEmail = email.trim().lowercase()
            val loginRequest = LoginRequest(
                email = trimmedEmail,
                password = "dummy",
                isSsoUser = true
            )
            Log.d("GOOGLE", "Sending Google SSO request to "+RetrofitClient.BASE_URL+"api/auth/token: "+Gson().toJson(loginRequest))
            try {
                val response = RetrofitClient.apiService.validateAccount(loginRequest)
                Log.d("GOOGLE", "Google SSO response: code=${response.code()}, body=${response.body()}")
                if (response.isSuccessful) {
                    val result = response.body()
                    if (result == null) {
                        Log.e("GOOGLE", "Google SSO failed: Null response body")
                        Toast.makeText(this@LoginActivity, "Google login failed: Server returned no data", Toast.LENGTH_LONG).show()
                        googleSignInClient.signOut().addOnCompleteListener {
                            Log.d("GOOGLE", "Signed out after null response")
                        }
                        return@launch
                    }
                    when (result.resultType) {
                        1 -> {
                            val userId = result.resultData?.userId ?: 0L
                            sharedPreferences.edit()
                                .putString("user_email", trimmedEmail)
                                .putLong("user_id", userId)
                                .apply()
                            Log.d("GOOGLE", "Google SSO successful for email: $trimmedEmail, userId: $userId")
                            Toast.makeText(this@LoginActivity, result.resultMessage ?: "Google login successful", Toast.LENGTH_SHORT).show()
                            navigateToEducationPage()
                        }
                        0 -> {
                            val message = when (result.resultMessage) {
                                "User not found" -> "Google account not registered. Please contact support."
                                "Invalid email/phone or password" -> "Invalid Google account. Please try again."
                                else -> result.resultMessage ?: "Google login failed"
                            }
                            Log.e("GOOGLE", "Google SSO failed: email=$trimmedEmail, resultType=0, message=$message")
                            Toast.makeText(this@LoginActivity, message, Toast.LENGTH_LONG).show()
                            googleSignInClient.signOut().addOnCompleteListener {
                                Log.d("GOOGLE", "Signed out after user not found")
                            }
                        }
                        2 -> {
                            Log.e("GOOGLE", "Google SSO failed: email=$trimmedEmail, resultType=2, message=Account is inactive")
                            Toast.makeText(this@LoginActivity, "Account is inactive. Contact support to activate.", Toast.LENGTH_LONG).show()
                            googleSignInClient.signOut().addOnCompleteListener {
                                Log.d("GOOGLE", "Signed out after inactive account")
                            }
                        }
                        3 -> {
                            Log.d("GOOGLE", "Non-SSO account detected for email: $trimmedEmail, prompting for password")
                            Toast.makeText(this@LoginActivity, "Please enter your Udyothvi password", Toast.LENGTH_SHORT).show()
                            promptForPassword(trimmedEmail)
                        }
                        4 -> {
                            Log.e("GOOGLE", "Google SSO failed: email=$trimmedEmail, resultType=4, message=No password set")
                            Toast.makeText(this@LoginActivity, "No password set. Use SSO login.", Toast.LENGTH_LONG).show()
                            googleSignInClient.signOut().addOnCompleteListener {
                                Log.d("GOOGLE", "Signed out after no password set")
                            }
                        }
                        else -> {
                            Log.e("GOOGLE", "Google SSO failed: email=$trimmedEmail, resultType=${result.resultType}, message=Unknown error")
                            Toast.makeText(this@LoginActivity, "Google login failed: Unknown error (code: ${result.resultType})", Toast.LENGTH_LONG).show()
                            googleSignInClient.signOut().addOnCompleteListener {
                                Log.d("GOOGLE", "Signed out after unknown error")
                            }
                        }
                    }
                } else {
                    val errorBodyString = response.errorBody()?.string()
                    Log.d("GOOGLE", "Error body: $errorBodyString")
                    val result = errorBodyString?.let {
                        try {
                            Gson().fromJson(it, LoginResponse::class.java)
                        } catch (e: Exception) {
                            Log.e("GOOGLE", "Failed to parse errorBody: ${e.message}, raw=$errorBodyString", e)
                            null
                        }
                    }
                    val message = when {
                        result?.resultType == 0 -> when (result?.resultMessage) {
                            "User not found" -> "Google account not registered. Please contact support."
                            "Invalid email/phone or password" -> "Invalid Google account. Please try again."
                            else -> result?.resultMessage ?: "Google login failed: ${response.code()}"
                        }
                        result?.resultType == 2 -> "Account is inactive. Contact support to activate."
                        result?.resultType == 3 -> "Non-SSO account. Please provide password."
                        result?.resultType == 4 -> "No password set. Use SSO login."
                        else -> "Server error: ${response.code()}${if (errorBodyString != null) " - $errorBodyString" else ""}"
                    }
                    Log.e("GOOGLE", "Google SSO failed: email=$trimmedEmail, code=${response.code()}, resultType=${result?.resultType}, message=$message")
                    Toast.makeText(this@LoginActivity, message, Toast.LENGTH_LONG).show()
                    googleSignInClient.signOut().addOnCompleteListener {
                        Log.d("GOOGLE", "Signed out after server error")
                    }
                }
            } catch (e: Exception) {
                Log.e("GOOGLE", "Google SSO error: email=$trimmedEmail, error=${e.message}, stackTrace=${e.stackTraceToString()}", e)
                val errorMessage = when (e) {
                    is HttpException -> {
                        val errorBodyString = e.response()?.errorBody()?.string()
                        Log.d("GOOGLE", "HttpException errorBody: $errorBodyString")
                        val result = errorBodyString?.let {
                            try {
                                Gson().fromJson(it, LoginResponse::class.java)
                            } catch (parseEx: Exception) {
                                Log.e("GOOGLE", "Failed to parse HttpException errorBody: ${parseEx.message}, raw=$errorBodyString", parseEx)
                                null
                            }
                        }
                        when {
                            result?.resultType == 0 -> when (result?.resultMessage) {
                                "User not found" -> "Google account not registered. Please contact support."
                                "Invalid email/phone or password" -> "Invalid Google account. Please try again."
                                else -> result?.resultMessage ?: "Server error: ${e.code()}"
                            }
                            result?.resultType == 2 -> "Account is inactive. Contact support to activate."
                            else -> "Server error: ${e.code()} - ${e.message()}${if (errorBodyString != null) " ($errorBodyString)" else ""}"
                        }
                    }
                    is IOException -> "Network error: ${e.message ?: "Unable to connect"}"
                    is com.google.gson.JsonParseException -> "Invalid server response. Contact support."
                    else -> "Error: ${e.message ?: "Unknown error"}"
                }
                Log.e("GOOGLE", "Displaying error: $errorMessage")
                Toast.makeText(this@LoginActivity, errorMessage, Toast.LENGTH_LONG).show()
                googleSignInClient.signOut().addOnCompleteListener {
                    Log.d("GOOGLE", "Signed out after exception")
                }
            }
        }
    }

    @Composable
    private fun PromptForPasswordScreen(email: String, onSubmit: (String) -> Unit, onCancel: () -> Unit) {
        var password by remember { mutableStateOf("") }
        var passwordVisible by remember { mutableStateOf(false) }
        var isLoading by remember { mutableStateOf(false) }

        Surface(
            modifier = Modifier.fillMaxSize(),
            color = Color.White
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    "Enter your Udyothvi password for $email",
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold,
                    color = Color.Black
                )
                OutlinedTextField(
                    value = password,
                    onValueChange = { password = it },
                    label = { Text("Password", color = Color.Black) },
                    modifier = Modifier.fillMaxWidth(),
                    textStyle = LocalTextStyle.current.copy(color = Color.Black),
                    visualTransformation = if (passwordVisible) VisualTransformation.None else PasswordVisualTransformation(),
                    trailingIcon = {
                        Icon(
                            imageVector = if (passwordVisible) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                            contentDescription = if (passwordVisible) "Hide password" else "Show password",
                            modifier = Modifier.clickable { passwordVisible = !passwordVisible }.padding(4.dp),
                            tint = Color.Black
                        )
                    },
                    singleLine = true,
                    enabled = !isLoading
                )
                Spacer(modifier = Modifier.height(20.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Button(
                        onClick = onCancel,
                        modifier = Modifier.weight(1f).height(50.dp).padding(end = 8.dp),
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color.Gray),
                        enabled = !isLoading
                    ) {
                        Text("Cancel")
                    }
                    Button(
                        onClick = {
                            if (password.isNotEmpty()) {
                                isLoading = true
                                onSubmit(password)
                            } else {
                                Toast.makeText(this@LoginActivity, "Please enter a password", Toast.LENGTH_SHORT).show()
                            }
                        },
                        modifier = Modifier.weight(1f).height(50.dp).padding(start = 8.dp),
                        shape = RoundedCornerShape(8.dp),
                        enabled = !isLoading
                    ) {
                        if (isLoading) {
                            CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                        } else {
                            Text("Submit")
                        }
                    }
                }
            }
        }
    }

    private fun promptForPassword(email: String) {
        setContent {
            UdyothviTheme(darkTheme = false) {
                PromptForPasswordScreen(
                    email = email,
                    onSubmit = { password ->
                        CoroutineScope(Dispatchers.Main).launch { performLogin(email, password) }
                    },
                    onCancel = {
                        setContent {
                            UdyothviTheme(darkTheme = false) {
                                Surface(modifier = Modifier.fillMaxSize(), color = Color.White) {
                                    LoginScreen(
                                        onLoginClick = { email, password ->
                                            CoroutineScope(Dispatchers.Main).launch { performLogin(email, password) }
                                        },
                                        onGoogleSignInClick = {
                                            if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.GET_ACCOUNTS) == PackageManager.PERMISSION_GRANTED) {
                                                initiateGoogleSignIn()
                                            } else {
                                                permissionLauncher.launch(android.Manifest.permission.GET_ACCOUNTS)
                                            }
                                        },
                                        onRegisterClick = {
                                            startActivity(Intent(this@LoginActivity, RegistrationActivity::class.java))
                                        }
                                    )
                                }
                            }
                        }
                        googleSignInClient.signOut().addOnCompleteListener {
                            Log.d("GOOGLE", "Signed out after password prompt cancellation")
                        }
                    }
                )
            }
        }
    }

    private fun navigateToEducationPage() {
        val intent = Intent(this, EducationalQualificationActivity::class.java)
        startActivity(intent)
        finish()
    }
}