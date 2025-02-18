<script>
import {
  GlButton,
  GlModal,
  GlModalDirective,
  GlCard,
  GlIcon,
  GlDisclosureDropdown,
  GlCollapsibleListbox,
  GlFormGroup,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import branchRulesQuery from 'ee_else_ce/projects/settings/repository/branch_rules/graphql/queries/branch_rules.query.graphql';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { expandSection } from '~/settings_panels';
import { scrollToElement } from '~/lib/utils/common_utils';
import createBranchRuleMutation from './graphql/mutations/create_branch_rule.mutation.graphql';
import BranchRule from './components/branch_rule.vue';
import { I18N, PROTECTED_BRANCHES_ANCHOR, BRANCH_PROTECTION_MODAL_ID } from './constants';

export default {
  name: 'BranchRules',
  i18n: I18N,
  components: {
    BranchRule,
    GlButton,
    GlModal,
    GlFormGroup,
    GlCard,
    GlIcon,
    GlCollapsibleListbox,
    GlDisclosureDropdown,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  apollo: {
    branchRules: {
      query: branchRulesQuery,
      variables() {
        return {
          projectPath: this.projectPath,
        };
      },
      update(data) {
        return data.project?.branchRules?.nodes || [];
      },
      error() {
        createAlert({ message: this.$options.i18n.queryError });
      },
    },
  },
  inject: {
    projectPath: { default: '' },
    branchRulesPath: { default: '' },
  },
  data() {
    return {
      branchRules: [],
      branchRuleName: '',
      searchQuery: '',
    };
  },
  computed: {
    addRuleItems() {
      return [{ text: this.$options.i18n.branchName, action: () => this.openCreateRuleModal() }];
    },
    createRuleItems() {
      return this.isWildcardAvailable ? [this.wildcardItem] : this.filteredOpenBranches;
    },
    filteredOpenBranches() {
      const openBranches = window.gon.open_branches.map((item) => ({
        text: item.text,
        value: item.text,
      }));
      return openBranches.filter((item) => item.text.includes(this.searchQuery));
    },
    wildcardItem() {
      return { text: this.$options.i18n.createWildcard, value: this.searchQuery };
    },
    isWildcardAvailable() {
      return this.searchQuery.includes('*');
    },
    createRuleText() {
      return this.branchRuleName || this.$options.i18n.branchNamePlaceholder;
    },
    branchRuleEditPath() {
      return `${this.branchRulesPath}?branch=${encodeURIComponent(this.branchRuleName)}`;
    },
    primaryProps() {
      return {
        text: this.$options.i18n.createProtectedBranch,
        attributes: {
          variant: 'confirm',
          disabled: !this.branchRuleName,
        },
      };
    },
    cancelProps() {
      return {
        text: this.$options.i18n.createBranchRule,
      };
    },
  },
  methods: {
    showProtectedBranches() {
      // Protected branches section is on the same page as the branch rules section.
      expandSection(this.$options.protectedBranchesAnchor);
      scrollToElement(this.$options.protectedBranchesAnchor);
    },
    openCreateRuleModal() {
      this.$refs[this.$options.modalId].show();
    },
    handleBranchRuleSearch(query) {
      this.searchQuery = query;
    },
    addBranchRule() {
      this.$apollo
        .mutate({
          mutation: createBranchRuleMutation,
          variables: {
            projectPath: this.projectPath,
            name: this.branchRuleName,
          },
        })
        .then(() => {
          window.location.assign(this.branchRuleEditPath);
        })
        .catch(() => {
          createAlert({ message: this.$options.i18n.createBranchRuleError });
        });
    },
    selectBranchRuleName(branchName) {
      this.branchRuleName = branchName;
    },
  },
  modalId: BRANCH_PROTECTION_MODAL_ID,
  protectedBranchesAnchor: PROTECTED_BRANCHES_ANCHOR,
};
</script>

<template>
  <gl-card
    class="gl-new-card gl-overflow-hidden"
    header-class="gl-new-card-header"
    body-class="gl-new-card-body gl-px-0"
  >
    <template #header>
      <div class="gl-new-card-title-wrapper" data-testid="title">
        <h3 class="gl-new-card-title">
          {{ __('Branch Rules') }}
        </h3>
        <div class="gl-new-card-count">
          <gl-icon name="branch" class="gl-mr-2" />
          {{ branchRules.length }}
        </div>
      </div>
      <gl-disclosure-dropdown
        v-if="glFeatures.addBranchRule"
        :toggle-text="$options.i18n.addBranchRule"
        :items="addRuleItems"
        size="small"
        no-caret
      />
      <gl-button
        v-else
        v-gl-modal="$options.modalId"
        size="small"
        class="gl-ml-3"
        data-testid="add-branch-rule-button"
        >{{ $options.i18n.addBranchRule }}</gl-button
      >
    </template>
    <ul class="content-list">
      <branch-rule
        v-for="(rule, index) in branchRules"
        :key="`${rule.name}-${index}`"
        :name="rule.name"
        :is-default="rule.isDefault"
        :branch-protection="rule.branchProtection"
        :status-checks-total="
          rule.externalStatusChecks ? rule.externalStatusChecks.nodes.length : 0
        "
        :approval-rules-total="rule.approvalRules ? rule.approvalRules.nodes.length : 0"
        :matching-branches-count="rule.matchingBranchesCount"
        class="gl-px-5! gl-py-4!"
      />
      <div v-if="!branchRules.length" class="gl-new-card-empty gl-px-5 gl-py-4" data-testid="empty">
        {{ $options.i18n.emptyState }}
      </div>
    </ul>
    <gl-modal
      v-if="glFeatures.addBranchRule"
      :ref="$options.modalId"
      :modal-id="$options.modalId"
      :title="$options.i18n.createBranchRule"
      :action-primary="primaryProps"
      :action-cancel="cancelProps"
      @primary="addBranchRule"
      @change="searchQuery = ''"
    >
      <gl-form-group
        :label="$options.i18n.branchName"
        :description="$options.i18n.branchNameDescription"
      >
        <gl-collapsible-listbox
          v-model="branchRuleName"
          searchable
          :items="createRuleItems"
          :toggle-text="createRuleText"
          block
          @search="handleBranchRuleSearch"
          @select="selectBranchRuleName"
        >
          <template v-if="isWildcardAvailable" #list-item="{ item }">
            {{ item.text }}
            <code>{{ searchQuery }}</code>
          </template>
        </gl-collapsible-listbox>
      </gl-form-group>
    </gl-modal>
    <gl-modal
      v-else
      :ref="$options.modalId"
      :modal-id="$options.modalId"
      :title="$options.i18n.addBranchRule"
      :ok-title="$options.i18n.createProtectedBranch"
      @ok="showProtectedBranches"
    >
      <p>{{ $options.i18n.branchRuleModalDescription }}</p>
      <p>{{ $options.i18n.branchRuleModalContent }}</p>
    </gl-modal>
  </gl-card>
</template>
