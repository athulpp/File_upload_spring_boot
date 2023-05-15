package com.example.app4.controller;

import java.io.IOException;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.example.app4.model.FileUpload;
import com.example.app4.service.FileUploadService;

@RestController
@RequestMapping("/api/uploads")
public class FileUploadController {
	
	public FileUploadController(FileUploadService fileUploadService) {
		super();
		this.fileUploadService = fileUploadService;
	}

	private final FileUploadService fileUploadService;
	
	@PostMapping
	public ResponseEntity<FileUpload>uploadFile(
			@RequestParam("ownedBy")String ownedBy,
			@RequestParam("description") String description,
			@RequestParam("file")MultipartFile file) throws IOException{
		
		FileUpload theFile=fileUploadService.uploadFile(ownedBy,description,file);
		return new ResponseEntity<>(theFile,HttpStatus.OK);
	}

}
