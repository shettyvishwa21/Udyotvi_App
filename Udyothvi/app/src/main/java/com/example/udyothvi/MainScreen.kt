package com.example.udyothvi

import android.content.Intent
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.navigation.NavController

@Composable
fun MainScreen(userEmail: String, navController: NavController) {
    val context = LocalContext.current
    val sharedPreferences = context.getSharedPreferences("UdyothviPrefs", android.content.Context.MODE_PRIVATE)

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.Center,
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(text = "Welcome, $userEmail", fontSize = 24.sp, color = Color.Black)
        Spacer(modifier = Modifier.height(20.dp))
        Button(
            onClick = { navController.navigate("education") },
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0073B1))
        ) {
            Text("Add Education", color = Color.White)
        }
        Spacer(modifier = Modifier.height(20.dp))
        Button(
            onClick = {
                sharedPreferences.edit().clear().apply()
                context.startActivity(Intent(context, LoginActivity::class.java))
                (context as? MainActivity)?.finish()
            },
            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF0073B1))
        ) {
            Text("Logout", color = Color.White)
        }
    }
}