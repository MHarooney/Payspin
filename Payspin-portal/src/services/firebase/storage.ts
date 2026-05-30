import { ref, uploadBytes, getDownloadURL, deleteObject, FirebaseStorage } from 'firebase/storage';
import { storage } from '../../config/firebase';

export class StorageService {
  private storageRef = storage;

  constructor() {
    if (!storage) {
      console.warn('Firebase Storage is not available. Image upload functionality will be disabled.');
    }
  }

  /**
   * Upload an image file to Firebase Storage
   * @param file - The image file to upload
   * @param path - The storage path (e.g., 'posts/images/')
   * @param filename - Optional custom filename
   * @returns Promise with the download URL
   */
  async uploadImage(file: File, path: string, filename?: string): Promise<string> {
    if (!this.storageRef) {
      throw new Error('Firebase Storage is not available. Please enable Firebase Storage in your project.');
    }

    try {
      // Generate a unique filename if not provided
      const fileName = filename || `${Date.now()}_${file.name}`;
      const fullPath = `${path}${fileName}`;
      
      // Create a reference to the file location
      const storageRef = ref(this.storageRef, fullPath);
      
      // Upload the file
      const snapshot = await uploadBytes(storageRef, file);
      
      // Get the download URL
      const downloadURL = await getDownloadURL(snapshot.ref);
      
      return downloadURL;
    } catch (error) {
      console.error('Error uploading image:', error);
      throw new Error('Failed to upload image');
    }
  }

  /**
   * Delete an image from Firebase Storage
   * @param url - The download URL of the image to delete
   */
  async deleteImage(url: string): Promise<void> {
    if (!this.storageRef) {
      throw new Error('Firebase Storage is not available. Please enable Firebase Storage in your project.');
    }

    try {
      // Extract the path from the URL
      const urlObj = new URL(url);
      const path = decodeURIComponent(urlObj.pathname.split('/o/')[1]?.split('?')[0] || '');
      
      if (!path) {
        throw new Error('Invalid image URL');
      }

      const storageRef = ref(this.storageRef, path);
      await deleteObject(storageRef);
    } catch (error) {
      console.error('Error deleting image:', error);
      throw new Error('Failed to delete image');
    }
  }

  /**
   * Compress and resize an image before upload
   * @param file - The original image file
   * @param maxWidth - Maximum width in pixels
   * @param maxHeight - Maximum height in pixels
   * @param quality - JPEG quality (0-1)
   * @returns Promise with the compressed file
   */
  async compressImage(
    file: File, 
    maxWidth: number = 1200, 
    maxHeight: number = 1200, 
    quality: number = 0.8
  ): Promise<File> {
    return new Promise((resolve, reject) => {
      const canvas = document.createElement('canvas');
      const ctx = canvas.getContext('2d');
      const img = new Image();

      img.onload = () => {
        // Calculate new dimensions
        let { width, height } = img;
        
        if (width > maxWidth) {
          height = (height * maxWidth) / width;
          width = maxWidth;
        }
        
        if (height > maxHeight) {
          width = (width * maxHeight) / height;
          height = maxHeight;
        }

        // Set canvas dimensions
        canvas.width = width;
        canvas.height = height;

        // Draw and compress image
        ctx?.drawImage(img, 0, 0, width, height);
        
        canvas.toBlob(
          (blob) => {
            if (blob) {
              const compressedFile = new File([blob], file.name, {
                type: 'image/jpeg',
                lastModified: Date.now(),
              });
              resolve(compressedFile);
            } else {
              reject(new Error('Failed to compress image'));
            }
          },
          'image/jpeg',
          quality
        );
      };

      img.onerror = () => reject(new Error('Failed to load image'));
      img.src = URL.createObjectURL(file);
    });
  }
}

export const storageService = new StorageService(); 