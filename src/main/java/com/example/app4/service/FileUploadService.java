package com.example.app4.service;


import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Objects;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import com.example.app4.exception.FileStorageException;
import com.example.app4.model.FileUpload;
import com.example.app4.repository.FileUploadRepository;


@Service("fileUploadService")
public class FileUploadService {
	
	private final FileUploadRepository fileUploadRepository;
	
	private FileUpload fileUpload;
	private java.nio.file.Path uploadLocation;
	
	
	@Autowired
	public FileUploadService(FileUploadRepository fileUploadRepository, FileUpload fileUpload) {
		super();
		this.fileUploadRepository = fileUploadRepository;
		this.fileUpload = fileUpload;
		
		this.uploadLocation=Paths.get(fileUpload.getUploadDir()).
				toAbsolutePath().normalize();
		
		try {
			Files.createDirectories(this.uploadLocation);
		}catch(Exception ex) {
			throw new FileStorageException("Could not create directory",ex);
		}
	}



	public FileUpload uploadFile(String ownedBy, String description, MultipartFile file) throws IOException {
		String originalFileName = StringUtils.cleanPath(Objects.requireNonNull(file.getOriginalFilename()));
		Path targetLocation =  this.uploadLocation.resolve(originalFileName);
		Files.copy(file.getInputStream(), targetLocation,StandardCopyOption.REPLACE_EXISTING);
		FileUpload theFile=new FileUpload();
		theFile.setOwnedBy(ownedBy);
		theFile.setDescription(description);
		theFile.setType(file.getContentType());
		theFile.setName(originalFileName);
		theFile.setFile(file.getBytes());
		theFile.setUploadDir(String.valueOf(this.uploadLocation));
		
		return fileUploadRepository.save(theFile);
	}

}
