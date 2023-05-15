package com.example.app4.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.example.app4.model.FileUpload;
@Repository
public interface FileUploadRepository extends JpaRepository<FileUpload, Long> {

}
