import React, { useState } from 'react';
import { Box, TextField, Button, Typography, Paper } from '@mui/material';
import ReactQuill from 'react-quill';
import 'react-quill/dist/quill.snow.css';
import { useNavigate } from 'react-router-dom';
import { BlogRepository } from '../services/firebase/repositories/BlogRepository';

interface BlogPost {
  title: string;
  content: string;
  coverImage?: string;
  publishDate: Date;
  author: string;
  status: 'draft' | 'published';
}

const BlogEditor: React.FC = () => {
  const navigate = useNavigate();
  const [post, setPost] = useState<BlogPost>({
    title: '',
    content: '',
    publishDate: new Date(),
    author: 'Admin', // This should come from auth context
    status: 'draft'
  });

  const handleTitleChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setPost({ ...post, title: event.target.value });
  };

  const handleContentChange = (content: string) => {
    setPost({ ...post, content });
  };

  const handleSave = async (status: 'draft' | 'published') => {
    try {
      const blogRepository = new BlogRepository();
      const updatedPost = { ...post, status };
      await blogRepository.create(updatedPost);
      navigate('/blogs');
    } catch (error) {
      console.error('Error saving blog post:', error);
      // TODO: Add proper error handling
    }
  };

  const modules = {
    toolbar: [
      [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
      ['bold', 'italic', 'underline', 'strike'],
      [{ 'list': 'ordered'}, { 'list': 'bullet' }],
      [{ 'color': [] }, { 'background': [] }],
      ['link', 'image'],
      ['clean']
    ],
  };

  return (
    <Box sx={{ maxWidth: 1200, margin: '0 auto', p: 3 }}>
      <Paper elevation={3} sx={{ p: 3 }}>
        <Typography variant="h4" gutterBottom>
          Create New Blog Post
        </Typography>
        
        <TextField
          fullWidth
          label="Title"
          variant="outlined"
          value={post.title}
          onChange={handleTitleChange}
          sx={{ mb: 3 }}
        />

        <Box sx={{ mb: 3 }}>
          <Typography variant="subtitle1" gutterBottom>
            Content
          </Typography>
          <ReactQuill
            theme="snow"
            value={post.content}
            onChange={handleContentChange}
            modules={modules}
            style={{ height: '400px', marginBottom: '50px' }}
          />
        </Box>

        <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end', mt: 5 }}>
          <Button
            variant="outlined"
            onClick={() => navigate('/blogs')}
          >
            Cancel
          </Button>
          <Button
            variant="outlined"
            onClick={() => handleSave('draft')}
          >
            Save as Draft
          </Button>
          <Button
            variant="contained"
            onClick={() => handleSave('published')}
            sx={{
              background: 'linear-gradient(45deg, #07D8DD 30%, #FC00FF 90%)',
              color: 'white',
            }}
          >
            Publish
          </Button>
        </Box>
      </Paper>
    </Box>
  );
};

export default BlogEditor; 