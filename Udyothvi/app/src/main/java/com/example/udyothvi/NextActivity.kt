package com.example.udyothvi

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.material3.*
import androidx.lifecycle.viewmodel.compose.viewModel

class NextActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val visibility = intent.getStringExtra("visibility") ?: "Private"
        
        setContent {
            val viewModel: ProfileViewModel = viewModel()
            viewModel.userProfile.value?.let { profile ->
                ProfilePage(
                    userProfile = profile,
                    onBackClick = { /* Disable back navigation */ }
                )
            }
        }
    }
} 