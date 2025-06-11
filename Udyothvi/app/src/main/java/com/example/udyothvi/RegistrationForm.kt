package com.example.udyothvi

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController
import com.google.gson.Gson
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import retrofit2.HttpException
import java.io.IOException
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.gson.annotations.SerializedName

data class RegisterRequest(
    @SerializedName("FirstName") val firstName: String,
    @SerializedName("LastName") val lastName: String,
    @SerializedName("PhoneNumber") val phoneNumber: String,
    @SerializedName("Email") val email: String,
    @SerializedName("Gender") val gender: String
)

data class UserData(
    @SerializedName("first_name") val firstName: String,
    @SerializedName("last_name") val lastName: String,
    @SerializedName("phone_number") val phoneNumber: String,
    @SerializedName("email") val email: String,
    @SerializedName("gender") val gender: Int
)

data class RegisterResponse(
    @SerializedName("resultMessage") val resultMessage: String?,
    @SerializedName("resultType") val resultType: Int,
    @SerializedName("resultData") val resultData: RegisterResultData?
)

data class RegisterResultData(
    @SerializedName("accountId") val accountId: Long?,
    @SerializedName("firstName") val firstName: String?,
    @SerializedName("lastName") val lastName: String?,
    @SerializedName("email") val email: String?,
    @SerializedName("phoneNumber") val phoneNumber: String?,
    @SerializedName("gender") val gender: Int?,
    @SerializedName("resultMessage") val resultMessage: String?,
    @SerializedName("resultType") val resultType: Int
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun RegistrationForm(
    navController: NavController,
    onRegistrationSuccess: () -> Unit,
    viewModel: ProfileViewModel = viewModel()
) {
    val context = LocalContext.current
    val sharedPreferences = context.getSharedPreferences("UdyothviPrefs", Context.MODE_PRIVATE)

    var firstName by remember { mutableStateOf(TextFieldValue("")) }
    var lastName by remember { mutableStateOf(TextFieldValue("")) }
    var email by remember { mutableStateOf(TextFieldValue("")) }
    var phoneNumber by remember { mutableStateOf(TextFieldValue("")) }
    var selectedCountryCode by remember { mutableStateOf("+91") }
    var gender by remember { mutableStateOf("") }

    var firstNameError by remember { mutableStateOf(false) }
    var lastNameError by remember { mutableStateOf(false) }
    var emailError by remember { mutableStateOf(false) }
    var phoneError by remember { mutableStateOf(false) }
    var firstNameErrorMsg by remember { mutableStateOf("") }
    var lastNameErrorMsg by remember { mutableStateOf("") }
    var emailErrorMsg by remember { mutableStateOf("") }
    var phoneErrorMsg by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.White)
            .padding(16.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Top
    ) {
        Text(
            "Create Your Account",
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = Color.Black,
            modifier = Modifier.padding(bottom = 16.dp)
        )

        // First Name Field
        OutlinedTextField(
            value = firstName,
            onValueChange = {
                firstName = it
                firstNameError = it.text.isBlank()
                firstNameErrorMsg = if (it.text.isBlank()) "First name is required" else ""
            },
            label = { Text("First Name", color = Color.Black) },
            isError = firstNameError,
            modifier = Modifier.fillMaxWidth(),
            colors = OutlinedTextFieldDefaults.colors(
                errorBorderColor = Color.Red,
                focusedBorderColor = Color(0xFF6200EE),
                unfocusedBorderColor = Color.Gray
            )
        )
        if (firstNameError) {
            Text(
                text = firstNameErrorMsg,
                color = Color.Red,
                fontSize = 12.sp,
                modifier = Modifier.align(Alignment.Start).padding(top = 4.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))

        // Last Name Field
        OutlinedTextField(
            value = lastName,
            onValueChange = {
                lastName = it
                lastNameError = it.text.isBlank()
                lastNameErrorMsg = if (it.text.isBlank()) "Last name is required" else ""
            },
            label = { Text("Last Name", color = Color.Black) },
            isError = lastNameError,
            modifier = Modifier.fillMaxWidth(),
            colors = OutlinedTextFieldDefaults.colors(
                errorBorderColor = Color.Red,
                focusedBorderColor = Color(0xFF6200EE),
                unfocusedBorderColor = Color.Gray
            )
        )
        if (lastNameError) {
            Text(
                text = lastNameErrorMsg,
                color = Color.Red,
                fontSize = 12.sp,
                modifier = Modifier.align(Alignment.Start).padding(top = 4.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))

        // Email Field
        OutlinedTextField(
            value = email,
            onValueChange = {
                email = it
                emailError = !android.util.Patterns.EMAIL_ADDRESS.matcher(it.text).matches()
                emailErrorMsg = if (!android.util.Patterns.EMAIL_ADDRESS.matcher(it.text).matches()) "Invalid email format" else ""
            },
            label = { Text("Email", color = Color.Black) },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Email),
            isError = emailError,
            modifier = Modifier.fillMaxWidth(),
            colors = OutlinedTextFieldDefaults.colors(
                errorBorderColor = Color.Red,
                focusedBorderColor = Color(0xFF6200EE),
                unfocusedBorderColor = Color.Gray
            )
        )
        if (emailError) {
            Text(
                text = emailErrorMsg,
                color = Color.Red,
                fontSize = 12.sp,
                modifier = Modifier.align(Alignment.Start).padding(top = 4.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))

        // Phone Number Field with Country Code
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            var countryExpanded by remember { mutableStateOf(false) }
            Box(modifier = Modifier.weight(0.3f)) {
                ExposedDropdownMenuBox(
                    expanded = countryExpanded,
                    onExpandedChange = { countryExpanded = !countryExpanded }
                ) {
                    OutlinedTextField(
                        value = selectedCountryCode,
                        onValueChange = {},
                        label = { Text("Code", color = Color.Black) },
                        readOnly = true,
                        modifier = Modifier.menuAnchor().fillMaxWidth(),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = Color(0xFF6200EE),
                            unfocusedBorderColor = Color.Gray
                        )
                    )
                    ExposedDropdownMenu(
                        expanded = countryExpanded,
                        onDismissRequest = { countryExpanded = false }
                    ) {
                        listOf("+91", "+1", "+44", "+61", "+86").forEach { code ->
                            DropdownMenuItem(
                                text = { Text(code, color = Color.Black) },
                                onClick = {
                                    selectedCountryCode = code
                                    countryExpanded = false
                                }
                            )
                        }
                    }
                }
            }

            OutlinedTextField(
                value = phoneNumber,
                onValueChange = {
                    phoneNumber = it
                    phoneError = it.text.length !in 10..15
                    phoneErrorMsg = if (it.text.length !in 10..15) "Phone number must be 10-15 digits" else ""
                },
                label = { Text("Phone Number", color = Color.Black) },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Phone),
                isError = phoneError,
                modifier = Modifier.weight(0.7f),
                colors = OutlinedTextFieldDefaults.colors(
                    errorBorderColor = Color.Red,
                    focusedBorderColor = Color(0xFF6200EE),
                    unfocusedBorderColor = Color.Gray
                )
            )
        }
        if (phoneError) {
            Text(
                text = phoneErrorMsg,
                color = Color.Red,
                fontSize = 12.sp,
                modifier = Modifier.align(Alignment.Start).padding(top = 4.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))

        // Gender Dropdown
        var genderExpanded by remember { mutableStateOf(false) }
        Box(modifier = Modifier.fillMaxWidth()) {
            ExposedDropdownMenuBox(
                expanded = genderExpanded,
                onExpandedChange = { genderExpanded = !genderExpanded }
            ) {
                OutlinedTextField(
                    value = gender.takeIf { it.isNotBlank() } ?: "Select Gender",
                    onValueChange = {},
                    readOnly = true,
                    label = { Text("Gender", color = Color.Black) },
                    modifier = Modifier.menuAnchor().fillMaxWidth(),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = Color(0xFF6200EE),
                        unfocusedBorderColor = Color.Gray
                    )
                )
                ExposedDropdownMenu(
                    expanded = genderExpanded,
                    onDismissRequest = { genderExpanded = false }
                ) {
                    listOf("Male", "Female", "Other").forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option, color = Color.Black) },
                            onClick = {
                                gender = option
                                genderExpanded = false
                            }
                        )
                    }
                }
            }
        }
        if (gender.isBlank()) {
            Text(
                text = "Please select gender",
                color = Color.Red,
                fontSize = 12.sp,
                modifier = Modifier.align(Alignment.Start).padding(top = 4.dp)
            )
        }
        Spacer(modifier = Modifier.height(16.dp))

        // Register Button
        Button(
            onClick = {
                firstNameError = firstName.text.isBlank()
                lastNameError = lastName.text.isBlank()
                emailError = !android.util.Patterns.EMAIL_ADDRESS.matcher(email.text).matches()
                phoneError = phoneNumber.text.length !in 10..15

                firstNameErrorMsg = if (firstNameError) "First name is required" else ""
                lastNameErrorMsg = if (lastNameError) "Last name is required" else ""
                emailErrorMsg = if (emailError) "Invalid email format" else ""
                phoneErrorMsg = if (phoneError) "Phone number must be 10-15 digits" else ""

                if (gender.isBlank()) {
                    Toast.makeText(context, "Please select gender", Toast.LENGTH_SHORT).show()
                    return@Button
                }

                if (!firstNameError && !lastNameError && !emailError && !phoneError) {
                    performRegistration(
                        firstName.text,
                        lastName.text,
                        email.text,
                        "${selectedCountryCode}${phoneNumber.text}",
                        gender,
                        sharedPreferences,
                        navController,
                        context,
                        viewModel,
                        onRegistrationSuccess
                    )
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF6200EE)),
            shape = RoundedCornerShape(24.dp)
        ) {
            Text("Register", color = Color.White, fontSize = 16.sp)
        }

        Spacer(modifier = Modifier.height(12.dp))

        Text("OR", fontSize = 16.sp, color = Color.Gray, modifier = Modifier.align(Alignment.CenterHorizontally))

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedButton(
            onClick = {
                val intent = Intent(context, MainActivity::class.java).apply {
                    putExtra("navigate_to_education", true)
                }
                context.startActivity(intent)
                (context as? ComponentActivity)?.finish()
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(50.dp),
            colors = ButtonDefaults.outlinedButtonColors(
                contentColor = Color(0xFF6200EE),
                containerColor = Color(0xFFF5F5F5)
            ),
            shape = RoundedCornerShape(8.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
                modifier = Modifier.fillMaxWidth()
            ) {
                Image(
                    painter = painterResource(id = R.drawable.google_logo),
                    contentDescription = "Google Logo",
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text("Continue with Google", color = Color(0xFF6200EE), fontSize = 16.sp)
            }
        }

        Spacer(modifier = Modifier.height(12.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text("Already have an account?", color = Color.Black)
            TextButton(onClick = { navController.navigate("login") }) {
                Text("Login", color = Color(0xFF6200EE))
            }
        }
    }
}

fun performRegistration(
    firstName: String,
    lastName: String,
    email: String,
    phone: String,
    gender: String,
    sharedPreferences: SharedPreferences,
    navController: NavController,
    context: Context,
    viewModel: ProfileViewModel,
    onRegistrationSuccess: () -> Unit
) {
    CoroutineScope(Dispatchers.Main).launch {
        try {
            val registerRequest = RegisterRequest(
                firstName = firstName.trim(),
                lastName = lastName.trim(),
                phoneNumber = phone.trim(),
                email = email.trim().lowercase(),
                gender = gender.trim()
            )

            Log.d("RegistrationForm", "Sending register request JSON: ${Gson().toJson(registerRequest)}")
            val response = RetrofitClient.apiService.registerAccount(registerRequest)
            Log.d("RegistrationForm", "Register response: code=${response.code()}, body=${response.body()}, errorBody=${response.errorBody()?.string()}")
            
            if (response.isSuccessful) {
                val result = response.body()
                if (result != null && result.resultType == 1) {
                    val defaultPassword = result.resultMessage?.let { msg ->
                        val regex = "Default password: (.+)".toRegex()
                        regex.find(msg)?.groupValues?.get(1)
                    }
                    
                    val userData = result.resultData
                    if (userData != null) {
                    sharedPreferences.edit()
                            .putString("user_email", userData.email ?: email.trim().lowercase())
                            .putLong("user_id", userData.accountId ?: 0L)
                            .putString("default_password", defaultPassword)
                        .apply()
                        
                        viewModel.updateProfile(
                            fullName = "${userData.firstName ?: firstName.trim()} ${userData.lastName ?: lastName.trim()}",
                            title = "",
                            company = "",
                            education = "",
                            location = "",
                            about = null
                        )
                        
                        val successMessage = if (defaultPassword != null) {
                            "Registration successful! Your default password is: $defaultPassword"
                        } else {
                            "Registration successful! Please check your email for login details."
                        }
                        Toast.makeText(context, successMessage, Toast.LENGTH_LONG).show()
                        
                        Log.d("RegistrationForm", "Registration resultMessage: ${result.resultMessage}")
                        Log.d("RegistrationForm", "Extracted defaultPassword: $defaultPassword")
                        
                        navController.navigate("educational_qualification") {
                            popUpTo("login") { inclusive = true }
                        }
                        
                        onRegistrationSuccess()
                    } else {
                        Toast.makeText(context, "Registration failed: Invalid response data", Toast.LENGTH_LONG).show()
                        Log.w("RegistrationForm", "Registration failed: Invalid response data")
                    }
                } else {
                    val errorMessage = result?.resultMessage ?: "Registration failed"
                    Toast.makeText(context, errorMessage, Toast.LENGTH_LONG).show()
                    Log.w("RegistrationForm", "Registration failed: $errorMessage")
                }
            } else {
                val errorBody = response.errorBody()?.string()
                val errorMessage = try {
                    val errorResult = Gson().fromJson(errorBody, RegisterResponse::class.java)
                    errorResult.resultMessage ?: "Registration failed: ${response.code()}"
                } catch (e: Exception) {
                    "Registration failed: ${response.code()}"
                }
                Toast.makeText(context, errorMessage, Toast.LENGTH_LONG).show()
                Log.w("RegistrationForm", "Failed with code ${response.code()}: $errorMessage")
            }
        } catch (e: Exception) {
            Log.e("RegistrationForm", "Error: ${e.message}", e)
            val errorMessage = when (e) {
                is HttpException -> "Server error: ${e.code()}"
                is IOException -> "Network error: ${e.message ?: "Unable to connect to server"}"
                else -> "Error: ${e.message ?: "Unknown error"}"
            }
            Toast.makeText(context, errorMessage, Toast.LENGTH_LONG).show()
            Log.w("RegistrationForm", "Exception: $errorMessage")
        }
    }
}