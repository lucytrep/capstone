export type LibraryItem = {
  id: string;
  kind: 'palette' | 'image';
  label: string;
  previewColor: string;
  secondaryColor: string;
  generationId: string;
  imageUrl?: string | number;
  thumbUrl?: string | number;
  alt?: string;
  source?: 'pexels' | 'unsplash' | 'gemini';
  author?: string;
  detailUrl?: string;
};

export type LibraryBoard = {
  id: string;
  promptTitle: string;
  itemCount: number;
  updatedAtLabel: string;
  generationId: string;
  items: LibraryItem[];
};

export type LibraryCollection = {
  id: 'latest' | 'individual';
  title: string;
  subtitle: string;
  countLabel: string;
  description: string;
  boardIds: string[];
};

const desertDream01 = require('../assets/desert-dreams-1.jpg');
const desertDream02 = require('../assets/desert-dreams-2.jpg');
const desertDream03 = require('../assets/desert-dreams-3.jpg');
const desertDream04 = require('../assets/desert-dreams-4.jpg');
const desertDream05 = require('../assets/desert-dreams-5.jpg');
const openCourt01 = require('../assets/open-court-1.jpg');
const openCourt02 = require('../assets/open-court-2.jpg');
const openCourt03 = require('../assets/open-court-3.jpg');
const openCourt04 = require('../assets/open-court-4.jpg');
const openCourt05 = require('../assets/open-court-5.jpg');
const nikeEditorial01 = require('../assets/nike-editorial-1.jpg');
const nikeEditorial02 = require('../assets/nike-editorial-2.jpg');
const nikeEditorial03 = require('../assets/nike-editorial-3.jpg');
const nikeEditorial04 = require('../assets/nike-editorial-4.jpg');
const nikeEditorial05 = require('../assets/nike-editorial-5.jpg');
const uiNikeGoChartreuseSwoosh = require('../assets/ui-nike-go-chartreuse-swoosh.png');
const recipeAppConcept03 = require('../assets/recipe-app-concept-3.jpg');
const recipeAppConcept04 = require('../assets/recipe-app-concept-4.jpg');
const recipeAppConcept05 = require('../assets/recipe-app-concept-5.jpg');
const softSpatialUi01 = require('../assets/soft-spatial-ui-1.png');
const softSpatialUi02 = require('../assets/soft-spatial-ui-2.png');
const softSpatialUi03 = require('../assets/soft-spatial-ui-3.png');
const softSpatialUi04 = require('../assets/soft-spatial-ui-4.png');

export const libraryBoards: LibraryBoard[] = [
  {
    id: 'rosewood-palette-board',
    promptTitle: 'Rosewood Palette',
    itemCount: 5,
    updatedAtLabel: 'Saved today',
    generationId: 'gen-rosewood-palette',
    items: [
      {
        id: 'rosewood-1',
        kind: 'palette',
        label: 'Soft cream',
        previewColor: '#F5E8DE',
        secondaryColor: '#FFF8F2',
        generationId: 'gen-rosewood-palette',
      },
      {
        id: 'rosewood-2',
        kind: 'palette',
        label: 'Blush clay',
        previewColor: '#E8B8A6',
        secondaryColor: '#F2D0C3',
        generationId: 'gen-rosewood-palette',
      },
      {
        id: 'rosewood-3',
        kind: 'palette',
        label: 'Rosewood',
        previewColor: '#A66C66',
        secondaryColor: '#C88D87',
        generationId: 'gen-rosewood-palette',
      },
      {
        id: 'rosewood-4',
        kind: 'palette',
        label: 'Sage',
        previewColor: '#8FA39A',
        secondaryColor: '#B2C4BC',
        generationId: 'gen-rosewood-palette',
      },
      {
        id: 'rosewood-5',
        kind: 'palette',
        label: 'Midnight',
        previewColor: '#1E2430',
        secondaryColor: '#384252',
        generationId: 'gen-rosewood-palette',
      },
    ],
  },
  {
    id: 'ui-controls-board',
    promptTitle: 'Soft Spatial UI',
    itemCount: 4,
    updatedAtLabel: 'Saved today',
    generationId: 'gen-soft-spatial-ui',
    items: [
      {
        id: 'ui-controls-1',
        kind: 'image',
        label: 'Avatar cluster',
        previewColor: '#F3E9D9',
        secondaryColor: '#F39B2C',
        generationId: 'gen-soft-spatial-ui',
        imageUrl: softSpatialUi01,
        thumbUrl: softSpatialUi01,
        alt: 'Avatar cluster with tooltip and soft floating profile circles',
        source: 'gemini',
        author: 'Draft',
      },
      {
        id: 'ui-controls-2',
        kind: 'image',
        label: 'Floating cards',
        previewColor: '#F8F3EA',
        secondaryColor: '#FF8B26',
        generationId: 'gen-soft-spatial-ui',
        imageUrl: softSpatialUi02,
        thumbUrl: softSpatialUi02,
        alt: 'Editorial UI composition with floating marketplace cards around centered copy',
        source: 'gemini',
        author: 'Draft',
      },
      {
        id: 'ui-controls-3',
        kind: 'image',
        label: 'Interest picker',
        previewColor: '#F7F3EB',
        secondaryColor: '#B62D1F',
        generationId: 'gen-soft-spatial-ui',
        imageUrl: softSpatialUi03,
        thumbUrl: softSpatialUi03,
        alt: 'Soft spatial onboarding screen with floating rounded image cards and a central selection tray',
        source: 'gemini',
        author: 'Draft',
      },
      {
        id: 'ui-controls-4',
        kind: 'image',
        label: 'Gather circles',
        previewColor: '#B8E8BC',
        secondaryColor: '#1F6B48',
        generationId: 'gen-soft-spatial-ui',
        imageUrl: softSpatialUi04,
        thumbUrl: softSpatialUi04,
        alt: 'Minimal onboarding card with selected and empty states in a floating spatial layout',
        source: 'gemini',
        author: 'Draft',
      },
    ],
  },
  {
    id: 'warm-kitchen-palette',
    promptTitle: 'Warm Kitchen Palette',
    itemCount: 6,
    updatedAtLabel: 'Saved today',
    generationId: 'gen-kitchen-palette',
    items: [
      {
        id: 'kitchen-1',
        kind: 'palette',
        label: 'Butter yellow',
        previewColor: '#C8873A',
        secondaryColor: '#E6BC65',
        generationId: 'gen-kitchen-palette',
      },
      {
        id: 'kitchen-2',
        kind: 'palette',
        label: 'Soft cream',
        previewColor: '#E8D2A5',
        secondaryColor: '#F3E7CA',
        generationId: 'gen-kitchen-palette',
      },
      {
        id: 'kitchen-3',
        kind: 'image',
        label: 'Tile reference',
        previewColor: '#8A6F52',
        secondaryColor: '#B2936B',
        generationId: 'gen-kitchen-palette',
        imageUrl:
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
        thumbUrl:
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=600&q=80',
        alt: 'Warm kitchen interior with natural wood and stone surfaces',
        source: 'unsplash',
        author: 'Unsplash',
      },
      {
        id: 'kitchen-4',
        kind: 'image',
        label: 'Cabinet detail',
        previewColor: '#6E5B43',
        secondaryColor: '#8F7A5F',
        generationId: 'gen-kitchen-palette',
        imageUrl:
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=1200&q=80',
        thumbUrl:
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?auto=format&fit=crop&w=600&q=80',
        alt: 'Kitchen cabinetry detail with warm wood tones',
        source: 'unsplash',
        author: 'Unsplash',
      },
      {
        id: 'kitchen-5',
        kind: 'palette',
        label: 'Olive accent',
        previewColor: '#6F7152',
        secondaryColor: '#8C8E6A',
        generationId: 'gen-kitchen-palette',
      },
      {
        id: 'kitchen-6',
        kind: 'image',
        label: 'Lighting',
        previewColor: '#AF8454',
        secondaryColor: '#D6A36A',
        generationId: 'gen-kitchen-palette',
        imageUrl:
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=1200&q=80',
        thumbUrl:
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=600&q=80',
        alt: 'Kitchen pendant lighting over a warm interior',
        source: 'unsplash',
        author: 'Unsplash',
      },
    ],
  },
  {
    id: 'yellow-kitchen-refresh',
    promptTitle: 'Desert Dreams',
    itemCount: 5,
    updatedAtLabel: 'Saved today',
    generationId: 'gen-desert-dreams',
    items: [
      {
        id: 'desert-1',
        kind: 'image',
        label: 'Sandstone portal',
        previewColor: '#BA7A47',
        secondaryColor: '#E5A16A',
        generationId: 'gen-desert-dreams',
        imageUrl: desertDream01,
        thumbUrl: desertDream01,
        alt: 'Warm desert interior framing a sunset landscape',
        source: 'gemini',
        author: 'Direction 1',
      },
      {
        id: 'desert-2',
        kind: 'image',
        label: 'Mirage runway',
        previewColor: '#D8875E',
        secondaryColor: '#F3B27E',
        generationId: 'gen-desert-dreams',
        imageUrl: desertDream02,
        thumbUrl: desertDream02,
        alt: 'Figure walking through a minimal desert scene at sunset',
        source: 'gemini',
        author: 'Direction 1',
      },
      {
        id: 'desert-3',
        kind: 'image',
        label: 'Ochre chamber',
        previewColor: '#B55E2F',
        secondaryColor: '#E3894A',
        generationId: 'gen-desert-dreams',
        imageUrl: desertDream03,
        thumbUrl: desertDream03,
        alt: 'Immersive installation glowing with orange desert light',
        source: 'gemini',
        author: 'Direction 1',
      },
      {
        id: 'desert-4',
        kind: 'image',
        label: 'Solar gesture',
        previewColor: '#C65A1B',
        secondaryColor: '#FFB14C',
        generationId: 'gen-desert-dreams',
        imageUrl: desertDream04,
        thumbUrl: desertDream04,
        alt: 'Silhouetted hands against a radiant amber background',
        source: 'gemini',
        author: 'Direction 1',
      },
      {
        id: 'desert-5',
        kind: 'image',
        label: 'Quiet horizon',
        previewColor: '#D3A184',
        secondaryColor: '#F0D1C1',
        generationId: 'gen-desert-dreams',
        imageUrl: desertDream05,
        thumbUrl: desertDream05,
        alt: 'Solitary figure overlooking a pastel desert expanse',
        source: 'gemini',
        author: 'Direction 1',
      },
    ],
  },
  {
    id: 'calm-bedroom-board',
    promptTitle: 'Open Court Energy',
    itemCount: 5,
    updatedAtLabel: 'Saved today',
    generationId: 'gen-open-court-energy',
    items: [
      {
        id: 'open-court-1',
        kind: 'image',
        label: 'Sky sole',
        previewColor: '#5DB7EA',
        secondaryColor: '#97D8F6',
        generationId: 'gen-open-court-energy',
        imageUrl: openCourt01,
        thumbUrl: openCourt01,
        alt: 'Low-angle fashion image with oversized shoes against a bright sky',
        source: 'gemini',
        author: 'Direction 2',
      },
      {
        id: 'open-court-2',
        kind: 'image',
        label: 'Parking lot chrome',
        previewColor: '#88B8D7',
        secondaryColor: '#CFDFEA',
        generationId: 'gen-open-court-energy',
        imageUrl: openCourt02,
        thumbUrl: openCourt02,
        alt: 'Sporty outdoor portrait with metallic sneakers and a parking lot backdrop',
        source: 'gemini',
        author: 'Direction 2',
      },
      {
        id: 'open-court-3',
        kind: 'image',
        label: 'Baseline chic',
        previewColor: '#2A5E9A',
        secondaryColor: '#75B4FF',
        generationId: 'gen-open-court-energy',
        imageUrl: openCourt03,
        thumbUrl: openCourt03,
        alt: 'Editorial tennis fashion on a bright blue court',
        source: 'gemini',
        author: 'Direction 2',
      },
      {
        id: 'open-court-4',
        kind: 'image',
        label: 'Sun visor serve',
        previewColor: '#8EB53F',
        secondaryColor: '#D6E86C',
        generationId: 'gen-open-court-energy',
        imageUrl: openCourt04,
        thumbUrl: openCourt04,
        alt: 'Outdoor tennis scene with lime court tones and sunlit styling',
        source: 'gemini',
        author: 'Direction 2',
      },
      {
        id: 'open-court-5',
        kind: 'image',
        label: 'Club colors',
        previewColor: '#E0D58B',
        secondaryColor: '#F7F0B7',
        generationId: 'gen-open-court-energy',
        imageUrl: openCourt05,
        thumbUrl: openCourt05,
        alt: 'Group portrait featuring colorful football-inspired streetwear',
        source: 'gemini',
        author: 'Direction 2',
      },
    ],
  },
  {
    id: 'recipe-app-concept',
    promptTitle: 'Recipe App Concept',
    itemCount: 3,
    updatedAtLabel: 'Saved today',
    generationId: 'gen-recipe-app-concept',
    items: [
      {
        id: 'recipe-app-concept-2',
        kind: 'image',
        label: 'Pop orbit',
        previewColor: '#FF7A1A',
        secondaryColor: '#A86DFF',
        generationId: 'gen-recipe-app-concept',
        imageUrl: recipeAppConcept03,
        thumbUrl: recipeAppConcept03,
        alt: 'Playful campaign collage with objects orbiting around bold copy',
        source: 'gemini',
        author: 'Direction 4',
      },
      {
        id: 'recipe-app-concept-3',
        kind: 'image',
        label: 'Tree scene',
        previewColor: '#7BBE4E',
        secondaryColor: '#B8D97D',
        generationId: 'gen-recipe-app-concept',
        imageUrl: recipeAppConcept04,
        thumbUrl: recipeAppConcept04,
        alt: 'Stylized outdoor tableau with figures perched in a tree',
        source: 'gemini',
        author: 'Direction 4',
      },
      {
        id: 'recipe-app-concept-4',
        kind: 'image',
        label: 'Air motion',
        previewColor: '#7198FF',
        secondaryColor: '#F49AE1',
        generationId: 'gen-recipe-app-concept',
        imageUrl: recipeAppConcept05,
        thumbUrl: recipeAppConcept05,
        alt: 'Dynamic fashion figures suspended mid-air against a gradient sky',
        source: 'gemini',
        author: 'Direction 4',
      },
    ],
  },
  {
    id: 'nike-editorial-board',
    promptTitle: 'Nike Editorial',
    itemCount: 6,
    updatedAtLabel: 'Saved today',
    generationId: 'gen-nike-editorial',
    items: [
      {
        id: 'nike-editorial-1',
        kind: 'image',
        label: 'Nike portrait',
        previewColor: '#F3D11E',
        secondaryColor: '#A83B25',
        generationId: 'gen-nike-editorial',
        imageUrl: nikeEditorial01,
        thumbUrl: nikeEditorial01,
        alt: 'Profile portrait with oversized Nike wordmark and bright cyan hair against a red background',
        source: 'gemini',
        author: 'Direction 5',
      },
      {
        id: 'nike-editorial-2',
        kind: 'image',
        label: 'City tote',
        previewColor: '#F3D11E',
        secondaryColor: '#7CB6F7',
        generationId: 'gen-nike-editorial',
        imageUrl: nikeEditorial02,
        thumbUrl: nikeEditorial02,
        alt: 'Low-angle street fashion image with a sculptural yellow bag in Times Square',
        source: 'gemini',
        author: 'Direction 5',
      },
      {
        id: 'nike-editorial-3',
        kind: 'image',
        label: 'Lime motion',
        previewColor: '#E4D01D',
        secondaryColor: '#ACB4C1',
        generationId: 'gen-nike-editorial',
        imageUrl: nikeEditorial03,
        thumbUrl: nikeEditorial03,
        alt: 'Dynamic low-angle fashion shot with a neon yellow garment against a pale sky',
        source: 'gemini',
        author: 'Direction 5',
      },
      {
        id: 'nike-editorial-4',
        kind: 'image',
        label: 'Typographic lockup',
        previewColor: '#F0CE18',
        secondaryColor: '#111111',
        generationId: 'gen-nike-editorial',
        imageUrl: nikeEditorial04,
        thumbUrl: nikeEditorial04,
        alt: 'Bold black typographic lockup on a bright yellow field',
        source: 'gemini',
        author: 'Direction 5',
      },
      {
        id: 'nike-editorial-5',
        kind: 'image',
        label: 'Get Into It',
        previewColor: '#D9DA8A',
        secondaryColor: '#D85A23',
        generationId: 'gen-nike-editorial',
        imageUrl: nikeEditorial05,
        thumbUrl: nikeEditorial05,
        alt: 'Poster-style campaign image with GET INTO IT typography and a model in yellow activewear',
        source: 'gemini',
        author: 'Direction 5',
      },
      {
        id: 'nike-go-chartreuse-swoosh',
        kind: 'image',
        label: 'GO Swoosh energy',
        previewColor: '#D4FF2E',
        secondaryColor: '#111111',
        generationId: 'gen-nike-editorial',
        imageUrl: uiNikeGoChartreuseSwoosh,
        thumbUrl: uiNikeGoChartreuseSwoosh,
        alt: 'Nike swoosh on neon chartreuse with GO typography and ripple line energy',
        source: 'gemini',
        author: 'Direction 5',
      },
    ],
  },
];

export const libraryCollections: LibraryCollection[] = [
  {
    id: 'latest',
    title: 'Latest',
    subtitle: 'Recent generations ready to revisit',
    countLabel: `${libraryBoards.length} boards`,
    description: 'Tap in to browse the most recent generations and continue sorting saves.',
    boardIds: libraryBoards.map((board) => board.id),
  },
  {
    id: 'individual',
    title: 'Individual',
    subtitle: 'Single saved images and swatches',
    countLabel: `${libraryBoards.reduce((total, board) => total + board.itemCount, 0)} items`,
    description: 'This is where individual pieces from a generation can live outside a full board.',
    boardIds: libraryBoards.filter((board) => board.items.some((item) => item.kind === 'image')).map((board) => board.id),
  },
];

export const getBoardById = (id: string) =>
  libraryBoards.find((board) => board.id === id);

export const getCollectionById = (id: string) =>
  libraryCollections.find((collection) => collection.id === id);
