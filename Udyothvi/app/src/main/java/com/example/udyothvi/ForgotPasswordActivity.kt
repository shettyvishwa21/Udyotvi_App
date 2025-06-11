package com.example.udyothvi

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.core.util.PatternsCompat
import com.example.udyothvi.ui.theme.UdyothviTheme
import kotlinx.coroutines.launch
import retrofit2.HttpException
import java.io.IOException

class ForgotPasswordActivity : ComponentActivity() {
    private val apiService = RetrofitClient.apiService

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            UdyothviTheme(darkTheme = false) {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = Color.White
                ) {
                    var input by remember { mutableStateOf("") }
                    var inputError by remember { mutableStateOf("") }
                    var showDialog by remember { mutableStateOf(false) }
                    var tempPassword by remember { mutableStateOf("") }
                    var userId by remember { mutableStateOf("") }
                    var dialogMessage by remember { mutableStateOf("") }
                    var isLoading by remember { mutableStateOf(false) }

                    val scope = rememberCoroutineScope()

                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Text("Forgot Password?", fontSize = 26.sp, fontWeight = FontWeight.Bold)

                        Spacer(modifier = Modifier.height(30.dp))

                        OutlinedTextField(
                            value = input,
                            onValueChange = {
                                input = it
                                inputError = if (PatternsCompat.EMAIL_ADDRESS.matcher(it).matches() || it.isEmpty()) "" else "Invalid email"
                            },
                            label = { Text("Email") },
                            modifier = Modifier.fillMaxWidth(),
                            isError = inputError.isNotEmpty(),
                            singleLine = true
                        )

                        if (inputError.isNotEmpty()) {
                            Text(
                                text = inputError,
                                color = Color.Red,
                                fontSize = 12.sp,
                                modifier = Modifier
                                    .align(Alignment.Start)
                                    .padding(top = 4.dp)
                            )
                        }

                        Spacer(modifier = Modifier.height(20.dp))

                        Button(
                            onClick = {
                                if (inputError.isEmpty() && input.isNotEmpty()) {
                                    isLoading = true
                                    scope.launch {
                                        try {
                                            val response = apiService.forgotPassword(ForgotPasswordRequest(input))
                                            if (response.isSuccessful && response.body()?.resultType == 1) {
                                                val data = response.body()?.resultData
                                                tempPassword = data?.tempPassword ?: ""
                                                userId = data?.userId ?: ""
                                                dialogMessage = response.body()?.resultMessage ?: "Password reset successful"
                                                showDialog = true
                                            } else {
                                                Toast.makeText(
                                                    this@ForgotPasswordActivity,
                                                    response.body()?.resultMessage ?: "Failed to reset password",
                                                    Toast.LENGTH_SHORT
                                                ).show()
                                            }
                                        } catch (e: IOException) {
                                            Toast.makeText(this@ForgotPasswordActivity, "Network error: ${e.message}", Toast.LENGTH_SHORT).show()
                                        } catch (e: HttpException) {
                                            Toast.makeText(this@ForgotPasswordActivity, "Server error: ${e.message}", Toast.LENGTH_SHORT).show()
                                        } finally {
                                            isLoading = false
                                        }
                                    }
                                } else {
                                    Toast.makeText(this@ForgotPasswordActivity, "Please enter a valid email", Toast.LENGTH_SHORT).show()
                                }
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(50.dp),
                            shape = RoundedCornerShape(8.dp),
                            enabled = !isLoading
                        ) {
                            if (isLoading) {
                                CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                            } else {
                                Text(text = "Continue")
                            }
                        }

                        Spacer(modifier = Modifier.height(20.dp))

                        Text(
                            text = "Back to Login",
                            color = Color.Blue,
                            modifier = Modifier.clickable {
                                finish()
                            }
                        )
                    }

                    if (showDialog) {
                        Dialog(onDismissRequest = { showDialog = false }) {
                            Surface(
                                shape = RoundedCornerShape(8.dp),
                                color = Color.White
                            ) {
                                Column(
                                    modifier = Modifier
                                        .padding(16.dp)
                                        .width(300.dp),
                                    horizontalAlignment = Alignment.CenterHorizontally
                                ) {
                                    Text("Temporary Password Generated", fontSize = 18.sp, fontWeight = FontWeight.Bold)
                                    Spacer(modifier = Modifier.height(16.dp))
                                    Text(dialogMessage)
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Text("Temporary Password: $tempPassword", fontSize = 16.sp)
                                    Text("User ID: $userId", fontSize = 16.sp)
                                    Spacer(modifier = Modifier.height(16.dp))
                                    Text("Click OK to change your password.", fontSize = 14.sp)
                                    Spacer(modifier = Modifier.height(16.dp))
                                    Button(
                                        onClick = {
                                            showDialog = false
                                            val intent = Intent(this@ForgotPasswordActivity, ChangePasswordActivity::class.java)
                                            intent.putExtra("userId", userId)
                                            intent.putExtra("tempPassword", tempPassword)
                                            startActivity(intent)
                                            finish()
                                        },
                                        modifier = Modifier.align(Alignment.End)
                                    ) {
                                        Text("OK")
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}