import { firebaseService } from '../services/firebase';

interface PostTypeData {
  name: string;
  label: string;
  description: string;
  isActive: boolean;
  order: number;
}

interface PostSubtypeData {
  name: string;
  label: string;
  description: string;
  postTypeId: string;
  isActive: boolean;
  order: number;
}

const defaultPostTypes: PostTypeData[] = [
  {
    name: 'news',
    label: 'News',
    description: 'Latest news, announcements, and updates',
    isActive: true,
    order: 1,
  },
  {
    name: 'offer',
    label: 'Offers',
    description: 'Special deals, discounts, and promotional content',
    isActive: true,
    order: 2,
  },
  {
    name: 'blog',
    label: 'Blogs',
    description: 'Editorial content, guides, and articles',
    isActive: true,
    order: 3,
  },
];

const defaultSubtypes: { [postType: string]: Omit<PostSubtypeData, 'postTypeId'>[] } = {
  news: [
    {
      name: 'announcement',
      label: 'Announcement',
      description: 'Important announcements and official statements',
      isActive: true,
      order: 1,
    },
    {
      name: 'update',
      label: 'Update',
      description: 'System updates, feature releases, and improvements',
      isActive: true,
      order: 2,
    },
    {
      name: 'event',
      label: 'Event',
      description: 'Upcoming events, webinars, and activities',
      isActive: true,
      order: 3,
    },
  ],
  offer: [
    {
      name: 'discount',
      label: 'Discount',
      description: 'Price reductions and discount offers',
      isActive: true,
      order: 1,
    },
    {
      name: 'promotion',
      label: 'Promotion',
      description: 'Promotional campaigns and special deals',
      isActive: true,
      order: 2,
    },
    {
      name: 'deal',
      label: 'Deal',
      description: 'Limited time deals and exclusive offers',
      isActive: true,
      order: 3,
    },
  ],
  blog: [
    {
      name: 'travel',
      label: 'Travel',
      description: 'Travel guides, tips, and destination content',
      isActive: true,
      order: 1,
    },
    {
      name: 'gifts',
      label: 'Gifts',
      description: 'Gift ideas, recommendations, and guides',
      isActive: true,
      order: 2,
    },
    {
      name: 'donations',
      label: 'Donations',
      description: 'Charitable giving and donation-related content',
      isActive: true,
      order: 3,
    },
    {
      name: 'events',
      label: 'Events',
      description: 'Event coverage, reviews, and highlights',
      isActive: true,
      order: 4,
    },
    {
      name: 'living',
      label: 'Living',
      description: 'Lifestyle, home, and daily living content',
      isActive: true,
      order: 5,
    },
    {
      name: 'savings',
      label: 'Savings',
      description: 'Money-saving tips, financial advice, and budgeting',
      isActive: true,
      order: 6,
    },
    {
      name: 'others',
      label: 'Others',
      description: 'Miscellaneous content that doesn\'t fit other categories',
      isActive: true,
      order: 7,
    },
  ],
};

export const seedPostTypes = async (): Promise<void> => {
  try {
    console.log('Starting post types and subtypes seeding...');

    // Check if post types already exist
    const existingTypes = await firebaseService.postTypes.getAll();
    if (existingTypes.length > 0) {
      console.log('Post types already exist. Skipping seeding.');
      return;
    }

    // Create post types and get their IDs
    const createdTypeIds: { [name: string]: string } = {};

    for (const typeData of defaultPostTypes) {
      try {
        const typeId = await firebaseService.postTypes.createPostType(typeData);
        createdTypeIds[typeData.name] = typeId;
        console.log(`Created post type: ${typeData.label} (${typeId})`);
      } catch (error) {
        console.error(`Error creating post type ${typeData.name}:`, error);
      }
    }

    // Create subtypes for each post type
    for (const [postTypeName, subtypes] of Object.entries(defaultSubtypes)) {
      const postTypeId = createdTypeIds[postTypeName];
      if (!postTypeId) {
        console.error(`Post type ID not found for ${postTypeName}`);
        continue;
      }

      for (const subtypeData of subtypes) {
        try {
          const subtypeWithTypeId: PostSubtypeData = {
            ...subtypeData,
            postTypeId,
          };
          
          const subtypeId = await firebaseService.postSubtypes.createSubtype(subtypeWithTypeId);
          console.log(`Created subtype: ${subtypeData.label} for ${postTypeName} (${subtypeId})`);
        } catch (error) {
          console.error(`Error creating subtype ${subtypeData.name} for ${postTypeName}:`, error);
        }
      }
    }

    console.log('Post types and subtypes seeding completed successfully!');
  } catch (error) {
    console.error('Error during seeding:', error);
    throw error;
  }
};

// Function to reset and reseed (useful for development)
export const resetAndSeedPostTypes = async (): Promise<void> => {
  try {
    console.log('Resetting and reseeding post types...');

    // Get all existing data
    const [existingTypes, existingSubtypes] = await Promise.all([
      firebaseService.postTypes.getAll(),
      firebaseService.postSubtypes.getAll(),
    ]);

    // Delete all existing subtypes first
    for (const subtype of existingSubtypes) {
      await firebaseService.postSubtypes.delete(subtype.id);
    }

    // Delete all existing types
    for (const type of existingTypes) {
      await firebaseService.postTypes.delete(type.id);
    }

    console.log('Existing data cleared. Starting fresh seeding...');

    // Now seed with fresh data
    await seedPostTypes();
  } catch (error) {
    console.error('Error during reset and seed:', error);
    throw error;
  }
};

// Export default for easy importing
export default seedPostTypes; 