
module RedmineSlackNotifier
  module SlackHelper
    include IssuesHelper
    include CustomFieldsHelper

    def make_attachment(options={})
      default = { mrkdwn_in: %w(pretext, text, title, fields, fallback) }
      default.merge(options)
    end

    def make_field(title, value, short = true)
      {
        title: I18n.t(title),
        value: escape(value),
        short: short,
      }
    end

    def version_link(versoin)
      "<#{version_url(fixed_version)}|#{fixed_version.to_s}>"
    end

    def issue_link(issue, options = {})
      text = issue.subject
      text = "*#{text}*" if options[:bold]
      "<#{issue_url(issue, only_path: false)}|#{text}>"
    end

    def indent(n)
      return "" if n.zero?

      ('　' * (n - 1)) + '└ '
    end

    def issue_title_link(issue)
      link = "[#{issue.project.name} - #{issue.tracker} ##{issue.id}]\n"

      ancestors = issue.root? ? [] : issue.ancestors.visible.to_a
      ancestors.each_with_index do |ancestor, i|
        link << indent(i)
        link << issue_link(ancestor)
        link << "\n"
      end

      link << indent(ancestors.length)
      link << issue_link(issue, bold: true)
      link << " - #{version_link(issue.fixed_version)}" if issue.fixed_version.present?
      link
    end

    def detail_text(detail)
      multiple = false
      show_diff = false
      no_details = false
      label = detail.prop_key
      value = detail.value
      old_value = detail.old_value

      case detail.property
      when 'cf'
        custom_field = detail.custom_field
        if custom_field
          label = custom_field.name
          if custom_field.format.class.change_no_details
            no_details = true
          elsif custom_field.format.class.change_as_diff
            show_diff = true
          else
            multiple = custom_field.multiple?
            value = format_value(value, custom_field) if value
            old_value = format_value(old_value, custom_field) if old_value
          end
        end

      when 'attachment'
        label = l(:label_attachment)
        if value
          attachment = Attachment.find(detail.prop_key)
          value = "<#{attachment_url attachment}|#{escape value}>" if attachment
        end

      when 'relation'
        if value && !old_value
          rel_issue = Issue.visible.find_by_id(value)
          value = rel_issue.nil? ? "#{l(:label_issue)} ##{value}" : issue_link(rel_issue)
        elsif old_value && !value
          rel_issue = Issue.visible.find_by_id(old_value)
          old_value = rel_issue.nil? ? "#{l(:label_issue)} ##{old_value}" : issue_link(rel_issue)
        end
        relation_type = IssueRelation::TYPES[detail.prop_key]
        label = l(relation_type[:name]) if relation_type

      when 'attr'
        field = detail.prop_key.to_s.gsub(/\_id$/, "")
        label = l(("field_" + field).to_sym)

        case field
        when 'title', 'subject'
          nil

        when 'description'
          show_diff = true

        when 'due_date', 'start_date'
          value = format_date(value) if value
          old_value = format_date(old_value) if old_value

        when 'done_ratio'
          value = "#{value}%"
          old_value = "#{old_value}%"

        when 'project', 'status', 'tracker', 'assigned_to',
              'priority', 'category', 'fixed_version'
          value = find_name_by_reflection(field, value)
          old_value = find_name_by_reflection(field, old_value)

        when 'estimated_hours'
          value = l_hours_short(value.to_f) unless value.blank?
          old_value = l_hours_short(old_value.to_f) unless old_value.blank?

        when 'is_private'
          value = l(detail.value == "0" ? :general_text_No : :general_text_Yes) unless detail.value.blank?
          old_value = l(detail.old_value == "0" ? :general_text_No : :general_text_Yes) unless detail.old_value.blank?

        when 'parent'
          label = l(:field_parent_issue)
          issue = Issue.find(value) if value
          value = issue_link(issue, escape(issue.subject)) if issue
          old_issue = Issue.find(old_value) if old_value
          old_value = issue_link(old_issue, escape(old_issue.subject)) if old_issue

        end
      end

      label = "*#{label}*"
      if no_details
        l(:text_journal_changed_no_detail, label: label)
      elsif show_diff
        s = l(:text_journal_changed_no_detail, label: label)
        diff_url = diff_journal_url(detail.journal_id, :detail_id => detail.id, :only_path => false)
        s << " (<#{diff_url}|#{l(:label_view_diff)}>)"
      elsif value.present?
        value = "_#{value}_"
        old_value = "_#{old_value}_"

        case detail.property
        when 'attr', 'cf'
          if detail.old_value.present?
            l(:text_journal_changed, label: label, old: old_value, new: value)
          elsif multiple
            l(:text_journal_added, label: label, value: value)
          else
            l(:text_journal_set_to, label: label, value: value)
          end
        when 'attachment', 'relation'
          l(:text_journal_added, label: label, old: old_value, value: value)
        end
      else
        old_value = "~_#{old_value.to_s}_~"
        l(:text_journal_deleted, label: label, old: old_value)
      end

    end

    def escape(msg)
      msg.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;')
    end


  end
end