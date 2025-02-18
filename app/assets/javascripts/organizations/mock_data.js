/* eslint-disable @gitlab/require-i18n-strings */

// This is temporary mock data that will be removed when completing the following:
// https://gitlab.com/gitlab-org/gitlab/-/issues/420777
// https://gitlab.com/gitlab-org/gitlab/-/issues/421441

import { organizationProjects } from 'ee_else_ce/organizations/mock_projects';

export { organizationProjects };

export const defaultOrganization = {
  id: 1,
  name: 'Default',
  web_url: '/-/organizations/default',
  avatar_url: null,
};

export const organizations = [
  {
    id: 'gid://gitlab/Organizations::Organization/1',
    name: 'My First Organization',
    descriptionHtml:
      '<p>This is where an organization can be explained in <strong>detail</strong></p>',
    avatarUrl: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61',
    webUrl: '/-/organizations/default',
    __typename: 'Organization',
  },
  {
    id: 'gid://gitlab/Organizations::Organization/2',
    name: 'Vegetation Co.',
    descriptionHtml:
      '<p> Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolt   Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt  Lorem ipsum dolor sit amet Lorem ipsum dolt<script>alert(1)</script></p>',
    avatarUrl: null,
    webUrl: '/-/organizations/default',
    __typename: 'Organization',
  },
  {
    id: 'gid://gitlab/Organizations::Organization/3',
    name: 'Dude where is my car?',
    descriptionHtml: null,
    avatarUrl: null,
    webUrl: '/-/organizations/default',
    __typename: 'Organization',
  },
];

export const organizationGroups = [
  {
    id: 'gid://gitlab/Group/29',
    fullName: 'Commit451',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/Commit451',
    descriptionHtml:
      '<p data-sourcepos="1:1-1:52" dir="auto">Autem praesentium vel ut ratione itaque ullam culpa. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Suspendisse libero sem, congue ut sem id, semper pharetra ante. Sed at dui ac nunc pellentesque congue. Phasellus posuere, nisl non pellentesque dignissim, lacus nisi molestie ex, vel placerat neque ligula non libero. Curabitur ipsum enim, pretium eu dignissim vitae, euismod nec nibh. Praesent eget ipsum eleifend, pellentesque tortor vel, consequat neque. Etiam suscipit dolor massa, sed consectetur nunc tincidunt ut. Suspendisse posuere malesuada finibus. Maecenas iaculis et diam eu iaculis. Proin at nulla sit amet erat sollicitudin suscipit sit amet a libero.</p>',
    avatarUrl: null,
    descendantGroupsCount: 0,
    projectsCount: 3,
    groupMembersCount: 2,
    visibility: 'public',
    userPermissions: {
      removeGroup: true,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
  {
    id: 'gid://gitlab/Group/33',
    fullName: 'Flightjs',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/flightjs',
    descriptionHtml:
      '<p data-sourcepos="1:1-1:60" dir="auto">Ipsa reiciendis deleniti officiis illum nostrum quo aliquam.</p>',
    avatarUrl: null,
    descendantGroupsCount: 4,
    projectsCount: 3,
    groupMembersCount: 1,
    visibility: 'private',
    userPermissions: {
      removeGroup: true,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
  {
    id: 'gid://gitlab/Group/24',
    fullName: 'Gitlab Org',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/gitlab-org',
    descriptionHtml:
      '<p data-sourcepos="1:1-1:64" dir="auto">Dolorem dolorem omnis impedit cupiditate pariatur officia velit.</p>',
    avatarUrl: null,
    descendantGroupsCount: 1,
    projectsCount: 1,
    groupMembersCount: 2,
    visibility: 'internal',
    userPermissions: {
      removeGroup: true,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
  {
    id: 'gid://gitlab/Group/27',
    fullName: 'Gnuwget',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/gnuwgetf',
    descriptionHtml:
      '<p data-sourcepos="1:1-1:47" dir="auto">Culpa soluta aut eius dolores est vel sapiente.</p>',
    avatarUrl: null,
    descendantGroupsCount: 4,
    projectsCount: 2,
    groupMembersCount: 3,
    visibility: 'public',
    userPermissions: {
      removeGroup: true,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
  {
    id: 'gid://gitlab/Group/31',
    fullName: 'Jashkenas',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/jashkenas',
    descriptionHtml: '<p data-sourcepos="1:1-1:25" dir="auto">Ut ut id aliquid nostrum.</p>',
    avatarUrl: null,
    descendantGroupsCount: 3,
    projectsCount: 3,
    groupMembersCount: 10,
    visibility: 'private',
    userPermissions: {
      removeGroup: true,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
  {
    id: 'gid://gitlab/Group/22',
    fullName: 'Toolbox',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/toolbox',
    descriptionHtml:
      '<p data-sourcepos="1:1-1:46" dir="auto">Quo voluptatem magnam facere voluptates alias.</p>',
    avatarUrl: null,
    descendantGroupsCount: 2,
    projectsCount: 3,
    groupMembersCount: 40,
    visibility: 'internal',
    userPermissions: {
      removeGroup: true,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
  {
    id: 'gid://gitlab/Group/35',
    fullName: 'Twitter',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/twitter',
    descriptionHtml:
      '<p data-sourcepos="1:1-1:40" dir="auto">Quae nulla consequatur assumenda id quo.</p>',
    avatarUrl: null,
    descendantGroupsCount: 20,
    projectsCount: 30,
    groupMembersCount: 100,
    visibility: 'public',
    userPermissions: {
      removeGroup: true,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
  {
    id: 'gid://gitlab/Group/73',
    fullName: 'test',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/test',
    descriptionHtml: '',
    avatarUrl: null,
    descendantGroupsCount: 1,
    projectsCount: 1,
    groupMembersCount: 1,
    visibility: 'private',
    userPermissions: {
      removeGroup: true,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
  {
    id: 'gid://gitlab/Group/74',
    fullName: 'Twitter / test subgroup',
    parent: null,
    webUrl: 'http://127.0.0.1:3000/groups/twitter/test-subgroup',
    descriptionHtml: '',
    avatarUrl: null,
    descendantGroupsCount: 4,
    projectsCount: 4,
    groupMembersCount: 4,
    visibility: 'internal',
    userPermissions: {
      removeGroup: false,
    },
    maxAccessLevel: {
      integerValue: 30,
    },
  },
];

export const organizationCreateResponse = {
  data: {
    organizationCreate: {
      organization: {
        id: 'gid://gitlab/Organizations::Organization/1',
        webUrl: 'http://127.0.0.1:3000/-/organizations/default',
      },
      errors: [],
    },
  },
};

export const organizationCreateResponseWithErrors = {
  data: {
    organizationCreate: {
      organization: null,
      errors: ['Path is too short (minimum is 2 characters)'],
    },
  },
};

export const organizationUpdateResponse = {
  data: {
    organizationUpdate: {
      organization: {
        id: 'gid://gitlab/Organizations::Organization/1',
        name: 'Default updated',
        webUrl: 'http://127.0.0.1:3000/-/organizations/default',
      },
      errors: [],
    },
  },
};

export const organizationUpdateResponseWithErrors = {
  data: {
    organizationUpdate: {
      organization: null,
      errors: ['Path is too short (minimum is 2 characters)'],
    },
  },
};

export const pageInfo = {
  endCursor: 'eyJpZCI6IjEwNTMifQ',
  hasNextPage: true,
  hasPreviousPage: true,
  startCursor: 'eyJpZCI6IjEwNzIifQ',
  __typename: 'PageInfo',
};

export const pageInfoOnePage = {
  endCursor: 'eyJpZCI6IjEwNTMifQ',
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: 'eyJpZCI6IjEwNzIifQ',
  __typename: 'PageInfo',
};

export const pageInfoEmpty = {
  endCursor: null,
  hasNextPage: false,
  hasPreviousPage: false,
  startCursor: null,
  __typename: 'PageInfo',
};
