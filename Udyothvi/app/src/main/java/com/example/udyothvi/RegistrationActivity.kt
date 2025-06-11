package com.example.udyothvi

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.Surface
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.udyothvi.ui.theme.UdyothviTheme

class RegistrationActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            UdyothviTheme(darkTheme = false) {
                Surface {
                    val navController = rememberNavController()
                    NavHost(navController, startDestination = "registration") {
                        composable("registration") { 
                            RegistrationForm(
                                navController = navController,
                                onRegistrationSuccess = {
                                    // Start EducationalQualificationActivity and finish current activity
                                    val intent = Intent(this@RegistrationActivity, EducationalQualificationActivity::class.java)
                                    startActivity(intent)
                                    finish()
                                }
                            )
                        }
                    }
                }
            }
        }
    }
}