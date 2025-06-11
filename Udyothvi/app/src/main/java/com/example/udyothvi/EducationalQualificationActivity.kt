package com.example.udyothvi

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.navigation.compose.rememberNavController
import com.example.udyothvi.education.navigation.setupNavGraph
import com.example.udyothvi.ui.theme.UdyothviTheme

class EducationalQualificationActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            UdyothviTheme {
                val navController = rememberNavController()
                setupNavGraph(navController)
            }
        }
    }
}