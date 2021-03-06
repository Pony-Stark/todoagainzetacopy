import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import "routing.dart" as routing;
import "../task.dart";
import "../todos_data.dart";
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedList = allListName;

  List<Widget> createSection(Section section, TodosData todosData) {
    var sectionTasks =
        todosData.getSection(section: section, selectedListID: selectedList);
    if (sectionTasks.length == 0) {
      return <Widget>[];
    }
    List<Widget> widgets = [
      Text(
        sectionToUIString(section),
        style: section != Section.overdue
            ? Theme.of(context).textTheme.subtitle1
            : Theme.of(context)
                .textTheme
                .subtitle1!
                .copyWith(color: Colors.red),
      ),
      SizedBox(height: 5),
    ];
    for (var task in sectionTasks) {
      widgets.add(ActivityCard(
        task: task,
        listName: todosData.activeLists[task.taskListID]!.listName,
        isOverdue: section == Section.overdue,
      ));
    }
    widgets.add(SizedBox(height: 20));
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TodosData>(
      builder: (context, todosData, x) {
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            //onPressed: (){},
            child: const Icon(Icons.add, size: 35),
            onPressed: () async {
              Navigator.pushNamed(context, routing.newTaskScreenID);
            },
          ),
          appBar: AppBar(
            leading: Icon(Icons.check_circle, size: 35),
            actions: [
              Icon(Icons.search, size: 30),
              PopupMenuButton<String>(itemBuilder: (context) {
                return [
                  PopupMenuItem<String>(
                    child: Text("Sign out"),
                    onTap: () async {
                      await GoogleSignIn().signOut();
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                          context, routing.socialSignInID, (route) => false);
                    },
                  ),
                ];
              }),
            ],
            title: todosData.isDataLoaded
                ? DropdownButton<String>(
                    iconEnabledColor: Theme.of(context).colorScheme.secondary,
                    underline: SizedBox(height: 0),
                    isExpanded: true,
                    items: () {
                      var activeLists = todosData.activeLists;
                      List<DropdownMenuItem<String>> menuItems = [];
                      menuItems.add(DropdownMenuItem<String>(
                        child: Text(
                          allListName,
                          style: Theme.of(context).textTheme.subtitle2,
                        ),
                        value: allListName,
                      ));
                      for (var taskList in activeLists.values) {
                        menuItems.add(DropdownMenuItem<String>(
                          child: Text(
                            taskList.listName,
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                          value: taskList.listID,
                        ));
                      }
                      return menuItems;
                    }(),
                    value: selectedList,
                    onChanged: (value) {
                      selectedList = value ?? selectedList;
                      setState(() {});
                    },
                  )
                : Text("Loading"),
          ),
          //body: function(s)
          body: () {
            {
              if (todosData.isDataLoaded) {
                List<Widget> children = [];

                for (var section in Section.values) {
                  var sectionWidgets = createSection(section, todosData);
                  children = [
                    ...children,
                    ...sectionWidgets,
                  ];
                }
                return ListView(
                  padding: const EdgeInsets.all(10),
                  children: children,
                );
              } else {
                //if future has not returned
                return Center(child: CircularProgressIndicator());
              }
            }
          }(),
        );
      },
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    required this.task,
    required this.listName,
    this.isOverdue = false,
    Key? key,
  }) : super(key: key);

  final Task task;
  final String listName;
  final bool isOverdue;

  String deadlineString(BuildContext context) {
    String deadlineDate = "";
    if (task.deadlineDate == null) {
      return "";
    } else {
      deadlineDate = DateFormat('EEEE, d MMM, yyyy').format(task.deadlineDate!);
      String deadlineTime = "";
      if (task.deadlineTime != null) {
        deadlineTime = task.deadlineTime!.format(context);
        return deadlineDate + ", " + deadlineTime;
      } else {
        return deadlineDate;
      }
    }
  }

  Color deadlineColor(context) {
    if (isOverdue)
      return Colors.red;
    else
      return Theme.of(context).textTheme.bodyText1!.color!;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routing.newTaskScreenID, arguments: task);
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Container(
          padding: EdgeInsets.all(10),
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Theme(
                  data: ThemeData(unselectedWidgetColor: Colors.white),
                  child: Checkbox(
                    onChanged: (value) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Are you sure you want to finish?"),
                          actions: [
                            TextButton(
                                child: Text("YES"),
                                onPressed: () {
                                  Provider.of<TodosData>(context, listen: false)
                                      .finishTask(task);
                                  Navigator.pop(context);
                                }),
                            TextButton(
                                child: Text("NO"),
                                onPressed: () {
                                  Navigator.pop(context);
                                }),
                          ],
                        ),
                      );
                    },
                    value: false,
                  ),
                ),
              ),
              Container(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.taskName,
                    style: Theme.of(context).textTheme.subtitle2,
                  ),
                  SizedBox(height: 5),
                  ...(task.deadlineDate == null
                      ? []
                      : [
                          Row(
                            children: [
                              Text(
                                deadlineString(context),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyText1!
                                    .copyWith(color: deadlineColor(context)),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              ...(task.isRepeating
                                  ? [
                                      Icon(Icons.repeat,
                                          color: deadlineColor(context),
                                          size: 20)
                                    ]
                                  : []),
                            ],
                          ),
                        ]),
                  Text(listName),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
