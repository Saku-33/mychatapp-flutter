import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String infoText = '';
  String email = '';
  String password = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
            padding: EdgeInsets.all(32),
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(labelText: "メールアドレス"),
                  onChanged: (String value) {
                    setState(() {
                      email = value;
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                    decoration: InputDecoration(labelText: "パスワード（６文字以上）"),
                    onChanged: (String value) {
                      setState(() {
                        password = value;
                      });
                    }),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        final UserCredential result =
                            await auth.createUserWithEmailAndPassword(
                                email: email, password: password);

                        final User user = result.user!;
                        setState(() {
                          infoText = "登録OK:${user.email}";
                        });
                      } catch (e) {
                        setState(() {
                          infoText = "登録NG:${e.toString()}";
                        });
                      }
                    },
                    child: Text("ユーザー登録"),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        final FirebaseAuth auth = FirebaseAuth.instance;
                        final result = await auth.signInWithEmailAndPassword(
                          email: email,
                          password: password,
                        );
                        await Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (context) {
                            return ChatPage(result.user!);
                          }),
                        );
                      } catch (e) {
                        setState(() {
                          infoText = "ログインNG:${e.toString()}";
                        });
                      }
                    },
                    child: Text("ログイン"),
                  ),
                ),
                const SizedBox(height: 8),
                Text(infoText)
              ],
            )),
      ),
    );
  }
}

class ChatPage extends StatelessWidget {
  ChatPage(this.user);
  final User user;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("チャット"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) {
                  return LoginPage();
                }),
              );
            },
          ),
        ],
      ),
      body: Column(children: [
        Container(
          padding: EdgeInsets.all(8),
          child: Text("ログイン情報：　${user.email}"),
        ),
        Expanded(
          child: FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('posts')
                .orderBy('date')
                .get(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final List<DocumentSnapshot> documents = snapshot.data!.docs;
                return ListView(
                  children: documents.map((document) {
                    return Card(
                      child: ListTile(
                        title: Text(document['text']),
                        subtitle: Text(document['email']),
                        trailing: document['email'] == user.email
                            ? IconButton(
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(document.id)
                                      .delete();
                                },
                                icon: Icon(Icons.delete))
                            : null,
                      ),
                    );
                  }).toList(),
                );
              }
              return Center(child: Text('読み込み中...'));
            },
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) {
              return AddPostPage(user);
            }),
          );
        },
      ),
    );
  }
}

class AddPostPage extends StatefulWidget {
  AddPostPage(this.user);
  final User user;

  @override
  _AddPostPageState createState() => _AddPostPageState();
}

class _AddPostPageState extends State<AddPostPage> {
  String messageText = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("チャット投稿"),
      ),
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextFormField(
              decoration: InputDecoration(labelText: '投稿メッセージ'),
              keyboardType: TextInputType.multiline,
              maxLines: 3,
              onChanged: (String value) {
                setState(() {
                  messageText = value;
                });
              },
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              child: ElevatedButton(
                child: Text('投稿'),
                onPressed: () async {
                  final date = DateTime.now().toLocal().toIso8601String();
                  final email = widget.user.email;
                  await FirebaseFirestore.instance
                      .collection('posts')
                      .doc()
                      .set({
                    'text': messageText,
                    'email': email,
                    'date': date,
                  });
                  Navigator.of(context).pop();
                },
              ),
            )
          ]),
    );
  }
}
