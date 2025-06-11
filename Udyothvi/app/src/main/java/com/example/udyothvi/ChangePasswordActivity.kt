package com.example.udyothvi

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Visibility
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.util.PatternsCompat
import com.example.udyothvi.ui.theme.UdyothviTheme
import kotlinx.coroutines.launch
import retrofit2.Response

class ChangePasswordActivity : ComponentActivity() {
    private val apiService = RetrofitClient.apiService
    private var userId: String? = null
    private var tempPassword: String? = null
    private val TAG = "ChangePasswordActivity"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        userId = intent.getStringExtra("userId")
        tempPassword = intent.getStringExtra("tempPassword")

        Log.d(TAG, "Received userId: $userId, tempPassword: $tempPassword")

        if (userId.isNullOrEmpty() || tempPassword.isNullOrEmpty()) {
            Toast.makeText(this, "Invalid user or temporary password", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        setContent {
            UdyothviTheme(darkTheme = false) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color.White
                ) {
                    ChangePasswordScreen()
                }
            }
        }
    }

    @Composable
    fun ChangePasswordScreen() {
        var tempInput by remember { mutableStateOf("") }
        var newPassword by remember { mutableStateOf("") }
        var retypePassword by remember { mutableStateOf("") }
        var tempError by remember { mutableStateOf("") }
        var newPasswordError by remember { mutableStateOf("") }
        var retypePasswordError by remember { mutableStateOf("") }
        var showTempPassword by remember { mutableStateOf(false) }
        var showNewPassword by remember { mutableStateOf(false) }
        var showRetypePassword by remember { mutableStateOf(false) }
        var requireSignIn by remember { mutableStateOf(true) }
        var isLoading by remember { mutableStateOf(false) }

        val scope = rememberCoroutineScope()

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Text(
                text = "Choose a new password.",
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "Enter your temporary password and create a new password that is at least 8 characters long.",
                fontSize = 14.sp,
                color = Color.Gray
            )
            Text(
                text = "What makes a strong password?",
                fontSize = 14.sp,
                color = Color.Blue,
                modifier = Modifier.clickable { /* TODO: Add help link */ }
            )

            Spacer(modifier = Modifier.height(20.dp))

            OutlinedTextField(
                value = tempInput,
                onValueChange = {
                    tempInput = it
                    tempError = if (it != tempPassword && it.isNotEmpty()) "Temporary password does not match" else ""
                },
                label = { Text("Temporary password") },
                modifier = Modifier.fillMaxWidth(),
                visualTransformation = if (showTempPassword) VisualTransformation.None else PasswordVisualTransformation(),
                trailingIcon = {
                    Icon(
                        imageVector = if (showTempPassword) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                        contentDescription = if (showTempPassword) "Hide password" else "Show password",
                        modifier = Modifier.clickable { showTempPassword = !showTempPassword }
                    )
                },
                isError = tempError.isNotEmpty(),
                singleLine = true
            )
            if (tempError.isNotEmpty()) {
                Text(
                    text = tempError,
                    color = Color.Red,
                    fontSize = 12.sp,
                    modifier = Modifier.align(Alignment.Start).padding(top = 4.dp)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = newPassword,
                onValueChange = {
                    newPassword = it
                    newPasswordError = if (it.length < 8 && it.isNotEmpty()) "Password must be at least 8 characters" else ""
                },
                label = { Text("New password") },
                modifier = Modifier.fillMaxWidth(),
                visualTransformation = if (showNewPassword) VisualTransformation.None else PasswordVisualTransformation(),
                trailingIcon = {
                    Icon(
                        imageVector = if (showNewPassword) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                        contentDescription = if (showNewPassword) "Hide password" else "Show password",
                        modifier = Modifier.clickable { showNewPassword = !showNewPassword }
                    )
                },
                isError = newPasswordError.isNotEmpty(),
                singleLine = true
            )
            if (newPasswordError.isNotEmpty()) {
                Text(
                    text = newPasswordError,
                    color = Color.Red,
                    fontSize = 12.sp,
                    modifier = Modifier.align(Alignment.Start).padding(top = 4.dp)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            OutlinedTextField(
                value = retypePassword,
                onValueChange = {
                    retypePassword = it
                    retypePasswordError = if (it != newPassword && it.isNotEmpty()) "Passwords do not match" else ""
                },
                label = { Text("Retype new password") },
                modifier = Modifier.fillMaxWidth(),
                visualTransformation = if (showRetypePassword) VisualTransformation.None else PasswordVisualTransformation(),
                trailingIcon = {
                    Icon(
                        imageVector = if (showRetypePassword) Icons.Filled.Visibility else Icons.Filled.VisibilityOff,
                        contentDescription = if (showRetypePassword) "Hide password" else "Show password",
                        modifier = Modifier.clickable { showRetypePassword = !showRetypePassword }
                    )
                },
                isError = retypePasswordError.isNotEmpty(),
                singleLine = true
            )
            if (retypePasswordError.isNotEmpty()) {
                Text(
                    text = retypePasswordError,
                    color = Color.Red,
                    fontSize = 12.sp,
                    modifier = Modifier.align(Alignment.Start).padding(top = 4.dp)
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Checkbox(
                    checked = requireSignIn,
                    onCheckedChange = { requireSignIn = it }
                )
                Text(
                    text = "Require all devices to sign in with new password",
                    fontSize = 14.sp
                )
            }

            Spacer(modifier = Modifier.height(20.dp))

            Button(
                onClick = {
                    if (tempError.isEmpty() && newPasswordError.isEmpty() && retypePasswordError.isEmpty() &&
                        tempInput.isNotEmpty() && newPassword.isNotEmpty() && retypePassword.isNotEmpty()
                    ) {
                        isLoading = true
                        scope.launch {
                            try {
                                // Mock success response since backend is not connected
                                val mockResponse = Response.success(ChangePasswordResponse(resultType = 1, resultMessage = "Password changed successfully"))
                                if (mockResponse.isSuccessful && mockResponse.body()?.resultType == 1) {
                                    Toast.makeText(
                                        this@ChangePasswordActivity,
                                        mockResponse.body()?.resultMessage ?: "Password changed successfully",
                                        Toast.LENGTH_SHORT
                                    ).show()
                                    startActivity(Intent(this@ChangePasswordActivity, LoginActivity::class.java))
                                    finish()
                                } else {
                                    Toast.makeText(
                                        this@ChangePasswordActivity,
                                        mockResponse.body()?.resultMessage ?: "Failed to change password",
                                        Toast.LENGTH_SHORT
                                    ).show()
                                }
                            } catch (e: Exception) {
                                Log.e(TAG, "Error during mock response: ${e.message}", e)
                                Toast.makeText(this@ChangePasswordActivity, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                            } finally {
                                isLoading = false
                            }
                        }
                    } else {
                        Toast.makeText(this@ChangePasswordActivity, "Please fix the errors and try again", Toast.LENGTH_SHORT).show()
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(8.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0073B1)),
                enabled = !isLoading
            ) {
                if (isLoading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text(text = "Submit", color = Color.White)
                }
            }
        }
    }
}