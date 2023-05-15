package com.example.app4.model;

import java.io.Serializable;
import java.net.URI;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Lob;
import jakarta.persistence.Table;
import lombok.Data;

@SuppressWarnings("serial")
@Data
@Entity
@Table(name="file_upload")
@Component
@ConfigurationProperties(prefix="file")

public class FileUpload  implements Serializable {
	
	@Id
	@GeneratedValue(strategy=GenerationType.IDENTITY)
	private Long id;

	 
	private String name;
	private String type;
	private String ownedBy;
	private String description;
	@Lob
	@Column(columnDefinition = "LONGBLOB")
	private byte[] file;
	@Column(name="upload_dir")
	private String uploadDir;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getOwnedBy() {
		return ownedBy;
	}

	public void setOwnedBy(String ownedBy) {
		this.ownedBy = ownedBy;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public byte[] getFile() {
		return file;
	}

	public void setFile(byte[] file) {
		this.file = file;
	}

	public String getUploadDir() {
		return uploadDir;
	}

	public void setUploadDir(String uploadDir) {
		this.uploadDir = uploadDir;
	}

	public FileUpload(Long id, String name, String type, String ownedBy, String description, byte[] file,
			String uploadDir) {
		super();
		this.id = id;
		this.name = name;
		this.type = type;
		this.ownedBy = ownedBy;
		this.description = description;
		this.file = file;
		this.uploadDir = uploadDir;
	}

	public FileUpload() {
		super();
		// TODO Auto-generated constructor stub
	}
	
	


	

}
