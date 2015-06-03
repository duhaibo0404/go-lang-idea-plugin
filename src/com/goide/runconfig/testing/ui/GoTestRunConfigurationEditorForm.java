/*
 * Copyright 2013-2015 Sergey Ignatov, Alexander Zolotov, Mihai Toader, Florin Patan
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.goide.runconfig.testing.ui;

import com.goide.runconfig.GoRunUtil;
import com.goide.runconfig.testing.GoTestRunConfigurationBase;
import com.goide.runconfig.ui.GoCommonSettingsPanel;
import com.intellij.openapi.module.Module;
import com.intellij.openapi.options.ConfigurationException;
import com.intellij.openapi.options.SettingsEditor;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.ui.TextFieldWithBrowseButton;
import com.intellij.openapi.util.text.StringUtil;
import com.intellij.ui.EditorTextField;
import com.intellij.ui.ListCellRendererWrapper;
import com.intellij.util.Producer;
import org.intellij.lang.regexp.RegExpLanguage;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

public class GoTestRunConfigurationEditorForm extends SettingsEditor<GoTestRunConfigurationBase> {
  @NotNull private final Project myProject;
  private JPanel myComponent;
  private EditorTextField myPatternEditor;

  private JComboBox myTestKindComboBox;
  private JLabel myFileLabel;
  private TextFieldWithBrowseButton myFileField;
  private JLabel myPackageLabel;
  private EditorTextField myPackageField;
  private JLabel myDirectoryLabel;
  private TextFieldWithBrowseButton myDirectoryField;
  private JLabel myPatternLabel;
  private GoCommonSettingsPanel myCommonSettingsPanel;

  public GoTestRunConfigurationEditorForm(@NotNull final Project project) {
    super(null);
    myProject = project;
    myCommonSettingsPanel.init(project);

    installTestKindComboBox();
    installFileChoosers(project);
  }

  private void onTestKindChanged() {
    GoTestRunConfigurationBase.Kind selectedKind = (GoTestRunConfigurationBase.Kind)myTestKindComboBox.getSelectedItem();
    if (selectedKind == null) {
      selectedKind = GoTestRunConfigurationBase.Kind.DIRECTORY;
    }
    boolean allInPackage = selectedKind == GoTestRunConfigurationBase.Kind.PACKAGE;
    boolean allInDirectory = selectedKind == GoTestRunConfigurationBase.Kind.DIRECTORY;
    boolean file = selectedKind == GoTestRunConfigurationBase.Kind.FILE;

    myPackageField.setVisible(allInPackage);
    myPackageLabel.setVisible(allInPackage);
    myDirectoryField.setVisible(allInDirectory);
    myDirectoryLabel.setVisible(allInDirectory);
    myFileField.setVisible(file);
    myFileLabel.setVisible(file);
    myPatternEditor.setVisible(!file);
    myPatternLabel.setVisible(!file);
  }

  @Override
  protected void resetEditorFrom(@NotNull GoTestRunConfigurationBase configuration) {
    myTestKindComboBox.setSelectedItem(configuration.getKind());
    myPackageField.setText(configuration.getPackage());

    String directoryPath = configuration.getDirectoryPath();
    myDirectoryField.setText(directoryPath.isEmpty() ? configuration.getProject().getBasePath() : directoryPath);

    String filePath = configuration.getFilePath();
    myFileField.setText(filePath.isEmpty() ? configuration.getProject().getBasePath() : filePath);

    myPatternEditor.setText(configuration.getPattern());

    myCommonSettingsPanel.resetEditorFrom(configuration);
  }

  @Override
  protected void applyEditorTo(@NotNull GoTestRunConfigurationBase configuration) throws ConfigurationException {
    configuration.setKind((GoTestRunConfigurationBase.Kind)myTestKindComboBox.getSelectedItem());
    configuration.setPackage(myPackageField.getText());
    configuration.setDirectoryPath(myDirectoryField.getText());
    configuration.setFilePath(myFileField.getText());
    configuration.setPattern(myPatternEditor.getText());

    myCommonSettingsPanel.applyEditorTo(configuration);
  }

  @NotNull
  @Override
  protected JComponent createEditor() {
    return myComponent;
  }

  @Override
  protected void disposeEditor() {
    myComponent.setVisible(false);
  }

  private void createUIComponents() {
    myPatternEditor = new EditorTextField("", null, RegExpLanguage.INSTANCE.getAssociatedFileType());
    myPackageField = new GoPackageFieldCompletionProvider(new Producer<Module>() {
      @Nullable
      @Override
      public Module produce() {
        return myCommonSettingsPanel != null ? myCommonSettingsPanel.getSelectedModule() : null;
      }
    }).createEditor(myProject);
  }

  @Nullable
  private static ListCellRendererWrapper<GoTestRunConfigurationBase.Kind> getTestKindListCellRendererWrapper() {
    return new ListCellRendererWrapper<GoTestRunConfigurationBase.Kind>() {
      @Override
      public void customize(JList list, @Nullable GoTestRunConfigurationBase.Kind kind, int index, boolean selected, boolean hasFocus) {
        if (kind != null) {
          String kindName = StringUtil.capitalize(kind.toString().toLowerCase());
          setText(kindName);
        }
      }
    };
  }

  private void installFileChoosers(@NotNull Project project) {
    GoRunUtil.installFileChooser(project, myFileField, false);
    GoRunUtil.installFileChooser(project, myDirectoryField, true);
  }

  private void installTestKindComboBox() {
    myTestKindComboBox.removeAllItems();
    myTestKindComboBox.setRenderer(getTestKindListCellRendererWrapper());
    for (GoTestRunConfigurationBase.Kind kind : GoTestRunConfigurationBase.Kind.values()) {
      myTestKindComboBox.addItem(kind);
    }
    myTestKindComboBox.addActionListener(new ActionListener() {
      @Override
      public void actionPerformed(@NotNull ActionEvent e) {
        onTestKindChanged();
      }
    });
  }
}
