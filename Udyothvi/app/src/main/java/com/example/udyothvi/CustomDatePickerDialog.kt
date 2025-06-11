package com.example.udyothvi

import android.widget.CalendarView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.viewinterop.AndroidView
import java.util.*

@Composable
fun CustomDatePickerDialog(
    onDismiss: () -> Unit,
    onDateSelected: (Long) -> Unit,
    title: String,
    calendar: Calendar = Calendar.getInstance()
) {
    Dialog(onDismissRequest = onDismiss) {
        Surface(
            modifier = Modifier
                .fillMaxWidth()
                .wrapContentHeight(),
            shape = RoundedCornerShape(16.dp),
            color = Color.White
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleLarge,
                    modifier = Modifier.padding(bottom = 16.dp)
                )

                AndroidView(
                    modifier = Modifier.wrapContentSize(),
                    factory = { context ->
                        CalendarView(context).apply {
                            date = calendar.timeInMillis
                            setOnDateChangeListener { _, year, month, dayOfMonth ->
                                calendar.set(year, month, dayOfMonth)
                            }
                        }
                    }
                )

                Row(
                                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 16.dp),
                    horizontalArrangement = Arrangement.End
                ) {
                    TextButton(onClick = onDismiss) {
                        Text("Cancel")
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Button(
                        onClick = { onDateSelected(calendar.timeInMillis) },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF6200EE))
                    ) {
                        Text("OK")
                    }
                }
            }
        }
    }
} 